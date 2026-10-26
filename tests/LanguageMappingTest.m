classdef LanguageMappingTest < matlab.unittest.TestCase
% LANGUAGEMAPPINGTEST  Headless tests for the language-mapping task battery.
%
% Covers the pure logic (block order, item selection, seeds, nonsense
% strings, logging/CSV columns, stimulus loader, config sanity) and runs all
% four tasks end to end against the Psychtoolbox stubs in tests/stubs, which
% replace the screen, keyboard and clock with a virtual clock. No
% Psychtoolbox installation is needed.
%
% Run with:  run tests/run_tests.m   (or  runtests('tests'))

    properties
        RepoRoot
        TmpDir
    end

    methods (TestClassSetup)
        function addPaths(tc)
            % Put the battery, its helpers and the PTB stubs on the path.
            tc.RepoRoot = fileparts(fileparts(mfilename('fullpath')));
            tc.applyFixture(matlab.unittest.fixtures.PathFixture(tc.RepoRoot));
            tc.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(tc.RepoRoot, 'helpers')));
            tc.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(tc.RepoRoot, 'tests')));
            tc.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(tc.RepoRoot, 'tests', 'stubs')));
        end
    end

    methods (TestMethodSetup)
        function freshState(tc)
            % Temp folder, reset virtual clock, empty event log.
            f = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            tc.TmpDir = f.Folder;
            ptbStubControl('reset');
            initExperimentLog();
        end
    end

    methods (Static)
        function c = cfg(varargin)
            % Placeholder config (ignores any local stimulus file).
            % Optional name/value overrides of top-level fields, e.g. cfg('sessionID','ses02').
            c = config_language_mapping(struct('useLocalStimuli', false));
            for i = 1:2:numel(varargin)
                c.(varargin{i}) = varargin{i+1};
            end
        end
    end

    methods
        function [config, T] = simulate(tc, config, taskIds)
            % Run the given tasks headless and return the event log as a table.
            config.dataFolder = tc.TmpDir;
            config.trigger.logFile = fullfile(tc.TmpDir, 'triggers.txt');
            config.effectiveSeed = subjectSeed(config.randomSeed, config.subjectID, config.sessionID);
            rng(config.effectiveSeed);
            initExperimentLog();
            config.sync = struct('tZeroGetSecs', GetSecs, 'tZeroPosix', 0, ...
                'tZeroClock', "", 'timeZone', "");
            fns = {@runVerbGeneration, @runSemanticRelatedness, ...
                   @runPhonemicFluency, @runSentenceCompletion}; %#ok<NASGU> used inside evalc
            for t = taskIds
                evalc('fns{t}(10, config)');
            end
            global EXPLOG %#ok<GVMIS>
            T = struct2table(EXPLOG);
        end
    end

    % =====================================================================
    methods (Test)

        % ---- entry point ------------------------------------------------
        function testMainParses(tc)
            % The entry point must parse (its first line used to hold stray text).
            tc.verifyEqual(nargin('main_language_mapping_fNIRS'), 0);
            info = checkcode(fullfile(tc.RepoRoot, 'main_language_mapping_fNIRS.m'));
            tc.verifyEmpty(info, 'Code Analyzer messages in main');
        end

        % ---- buildBlockOrder ---------------------------------------------
        function testBlockOrderCountsAndAlternation(tc)
            % 6 + 6 blocks, strictly alternating, starting with active.
            o = buildBlockOrder(LanguageMappingTest.cfg());
            tc.verifyEqual(numel(o), 12);
            tc.verifyEqual(sum(strcmp(o, 'active')), 6);
            tc.verifyEqual(sum(strcmp(o, 'control')), 6);
            tc.verifyEqual(o(1:2:end), repmat({'active'}, 1, 6));
            tc.verifyEqual(o(2:2:end), repmat({'control'}, 1, 6));
        end

        function testBlockOrderCounterbalanced(tc)
            % startWithActive = false flips every block.
            a = buildBlockOrder(LanguageMappingTest.cfg());
            b = buildBlockOrder(LanguageMappingTest.cfg('startWithActive', false));
            tc.verifyEqual(b{1}, 'control');
            tc.verifyTrue(all(~strcmp(a, b)));
        end

        % ---- pickItems / seeds -------------------------------------------
        function testPickItemsSessionsDisjoint(tc)
            % At the current pool sizes, sessions 1 and 2 share no items.
            c = LanguageMappingTest.cfg();
            pools = {c.t1.nouns, 24, 'verbgen'; (1:40)', 18, 'semrel'; ...
                     (1:40)', 18, 'semunr'; c.t4.activeSentences, 24, 'sentence'; ...
                     c.t3.letters, 6, 'fluency'};
            for i = 1:size(pools, 1)
                [pool, n, salt] = pools{i, :};
                s1 = pickItems(pool, n, LanguageMappingTest.cfg('sessionID', 'ses01'), salt);
                s2 = pickItems(pool, n, LanguageMappingTest.cfg('sessionID', 'ses02'), salt);
                tc.verifyNumElements(unique(s1), n, salt);
                tc.verifyEmpty(intersect(s1, s2), ['overlap in ' salt]);
            end
        end

        function testPickItemsDeterministicPerSubject(tc)
            % Same subject -> same draw; different subject -> different draw.
            c = LanguageMappingTest.cfg();
            a = pickItems(c.t1.nouns, 24, c, 'verbgen');
            rng(12345);   % global RNG state must not matter
            b = pickItems(c.t1.nouns, 24, c, 'verbgen');
            tc.verifyEqual(a, b);
            d = pickItems(c.t1.nouns, 24, LanguageMappingTest.cfg('subjectID', 'other'), 'verbgen');
            tc.verifyNotEqual(a, d);
        end

        function testPickItemsSessionIndexRule(tc)
            % Explicit sessionIndex equals the trailing number of the Session ID.
            pool = num2cell(1:60);
            a = pickItems(pool, 24, LanguageMappingTest.cfg('sessionID', 'visit02'), 'x');
            b = pickItems(pool, 24, LanguageMappingTest.cfg('sessionID', 'abc', 'sessionIndex', 2), 'x');
            tc.verifyEqual(a, b);
            tc.verifyEqual(sessionIndexReport(LanguageMappingTest.cfg('sessionID', 'visit02')), 2);
            tc.verifyEqual(sessionIndexReport(LanguageMappingTest.cfg('sessionID', 'abc')), 1);
        end

        function testPickItemsWarnsWhenPoolWraps(tc)
            % Session 3 of a 60-item pool drawing 24 must repeat items and warn.
            c = LanguageMappingTest.cfg('sessionIndex', 3);
            tc.verifyWarning(@() pickItems(num2cell(1:60), 24, c, 'x'), 'pickItems:wrapped');
        end

        function testSubjectSeed(tc)
            % Deterministic, positive, inside the 2^31-1 range, ID-sensitive.
            s = subjectSeed(1, 'test001', 'pilot001');
            tc.verifyEqual(s, subjectSeed(1, 'test001', 'pilot001'));
            tc.verifyGreaterThan(s, 0);
            tc.verifyLessThan(s, 2147483647);
            tc.verifyNotEqual(s, subjectSeed(1, 'test002', 'pilot001'));
            tc.verifyNotEqual(s, subjectSeed(1, 'test001', 'pilot002'));
            tc.verifyEqual(subjectSeed(5, 'a', 'b') - subjectSeed(0, 'a', 'b'), 5);
        end

        % ---- makeNonsenseStrings -----------------------------------------
        function testNonsenseStrings(tc)
            % n strings with one blank and a full stop; seeded; global RNG untouched.
            rng(7); before = rng;
            s = makeNonsenseStrings(24, 99);
            tc.verifyEqual(rng, before);
            tc.verifyNumElements(s, 24);
            tc.verifyEqual(s, makeNonsenseStrings(24, 99));
            tc.verifyNotEqual(s, makeNonsenseStrings(24, 100));
            for k = 1:24
                tc.verifyEqual(numel(strfind(s{k}, '___')), 1);
                tc.verifyTrue(endsWith(s{k}, '.'));
                tc.verifyTrue(ismember(numel(strsplit(s{k}, ' ')), [4 5]));
            end
        end

        % ---- config sanity -----------------------------------------------
        function testConfigTiming(tc)
            % 15 + 12x20 + 11x10 + 15 = 380 s of task, + 8 s break ~ 6.5 min.
            c = LanguageMappingTest.cfg();
            nBlocks = c.numActiveBlocks + c.numControlBlocks;
            tTask = 2 * c.restDuration + nBlocks * c.blockDuration + ...
                    (nBlocks - 1) * c.interRestDuration;
            tc.verifyEqual(tTask, 380);
            tc.verifyEqual((tTask + c.breakDuration) / 60, 6.5, 'AbsTol', 0.05);
            % trials must fit inside the shared block length
            tc.verifyLessThanOrEqual(c.t1.itemsPerBlock * (c.t1.stimDuration + c.t1.fixDuration), c.blockDuration);
            tc.verifyLessThanOrEqual(c.t2.trialsPerBlock * c.t2.trialDuration, c.blockDuration);
            tc.verifyLessThanOrEqual(c.t4.itemsPerBlock * c.t4.stimDuration, c.blockDuration);
            tc.verifyLessThanOrEqual(c.t2.stimMaxDur, c.t2.trialDuration);
        end

        function testPoolSizesCoverTwoSessions(tc)
            % Every drawn pool holds >= two sessions' worth (no repeats).
            c = LanguageMappingTest.cfg();
            nA = c.numActiveBlocks;
            tc.verifyGreaterThanOrEqual(numel(c.t1.nouns), 2 * nA * c.t1.itemsPerBlock);
            tc.verifyGreaterThanOrEqual(size(c.t2.relatedPairs, 1), 2 * nA * c.t2.trialsPerBlock / 2);
            tc.verifyGreaterThanOrEqual(size(c.t2.unrelatedPairs, 1), 2 * nA * c.t2.trialsPerBlock / 2);
            tc.verifyGreaterThanOrEqual(numel(c.t4.activeSentences), 2 * nA * c.t4.itemsPerBlock);
            tc.verifyGreaterThanOrEqual(numel(c.t3.letters), 2 * nA);
            tc.verifyGreaterThanOrEqual(numel(c.t3.controlPrompts), c.numControlBlocks);
        end

        function testPlaceholderLists(tc)
            % Placeholders have the study-list counts and are clearly labelled.
            c = LanguageMappingTest.cfg();
            tc.verifyEqual(c.stimulusSource, "placeholder");
            tc.verifySize(c.t1.nouns, [1 60]);
            tc.verifySize(c.t2.relatedPairs, [40 2]);
            tc.verifySize(c.t2.unrelatedPairs, [40 2]);
            tc.verifySize(c.t4.activeSentences, [1 55]);
            tc.verifyTrue(all(startsWith(c.t1.nouns, 'NOUN')));
            tc.verifyTrue(all(startsWith(c.t2.relatedPairs(:), 'REL')));
            tc.verifyTrue(all(startsWith(c.t2.unrelatedPairs(:), 'UNR')));
            tc.verifyTrue(all(startsWith(c.t4.activeSentences, 'PLACEHOLDER')));
            tc.verifyTrue(all(contains(c.t4.activeSentences, '___')));
            tc.verifyNumElements(unique(c.t4.activeSentences), 55);
        end

        function testDryRunConfig(tc)
            % dryRun shrinks counts/durations and leaves the full design otherwise.
            d = config_language_mapping(struct('dryRun', true, 'useLocalStimuli', false));
            tc.verifyTrue(d.dryRun);
            tc.verifyEqual([d.numActiveBlocks d.numControlBlocks], [2 2]);
            tc.verifyFalse(d.requireDemographics);
            tc.verifyEqual(d.skipSyncTests, 1);
            f = LanguageMappingTest.cfg();
            tc.verifyFalse(f.dryRun);
            tc.verifyEqual(f.skipSyncTests, 0);
        end

        % ---- stimulus loader ---------------------------------------------
        function testLoaderReadsTemplate(tc)
            % The shipped template is a valid stimulus file.
            c = LanguageMappingTest.cfg();
            tpl = fullfile(tc.RepoRoot, 'config', 'stimuli_local_template.m');
            [~, d] = evalc('loadStimulusLists(c, tpl)');
            tc.verifyEqual(d.stimulusSource, string(tpl));
            tc.verifySize(d.t1.nouns, [1 60]);
            tc.verifySize(d.t2.relatedPairs, [40 2]);
            tc.verifySize(d.t2.unrelatedPairs, [40 2]);
            tc.verifySize(d.t4.activeSentences, [1 55]);
            tc.verifyEqual(d.t3.letters, c.t3.letters);   % optional field kept
        end

        function testLoaderReadsUserFile(tc)
            % A user file in template format replaces the lists (column input -> row).
            f = fullfile(tc.TmpDir, 'my_stimuli.m');
            fid = fopen(f, 'w');
            fprintf(fid, 'function s = my_stimuli()\n');
            fprintf(fid, 's.nouns = arrayfun(@(k) sprintf(''w%%d'', k), (1:48)'', ''UniformOutput'', false);\n');
            fprintf(fid, 's.relatedPairs = repmat({''a'',''b''}, 36, 1);\n');
            fprintf(fid, 's.unrelatedPairs = repmat({''c'',''d''}, 36, 1);\n');
            fprintf(fid, 's.activeSentences = repmat({''x ___ y.''}, 1, 48);\n');
            fprintf(fid, 's.letters = {''A'',''B'',''C'',''D'',''E'',''G'',''H'',''I'',''J'',''K'',''L'',''M''};\n');
            fprintf(fid, 'end\n');
            fclose(fid);
            [~, d] = evalc('loadStimulusLists(LanguageMappingTest.cfg(), f)');
            tc.verifySize(d.t1.nouns, [1 48]);
            tc.verifyEqual(d.t1.nouns{48}, 'w48');
            tc.verifyEqual(d.t3.letters{end}, 'M');
            tc.verifyEqual(d.stimulusSource, string(f));
            tc.verifyEmpty(which('my_stimuli'), 'loader must restore the path');
        end

        function testLoaderMissingFileFallsBack(tc)
            % No local file -> placeholders kept, with a warning.
            c = LanguageMappingTest.cfg();
            d = tc.verifyWarning(@() loadStimulusLists(c, fullfile(tc.TmpDir, 'none.m')), ...
                'loadStimulusLists:placeholder');
            tc.verifyEqual(d.stimulusSource, "placeholder");
            tc.verifyEqual(d.t1.nouns, c.t1.nouns);
        end

        function testLoaderRejectsBadFiles(tc)
            % Too few items, missing blank, missing field, wrong pair shape.
            bodies = { ...
                {'s.nouns = {''a''};'}, 'loadStimulusLists:tooFew'; ...
                {'s.activeSentences = repmat({''no blank''}, 1, 48);'}, 'loadStimulusLists:blank'; ...
                {'s = rmfield(s, ''nouns'');'}, 'loadStimulusLists:missingField'; ...
                {'s.relatedPairs = s.relatedPairs(:, 1);'}, 'loadStimulusLists:shape'};
            for i = 1:size(bodies, 1)
                name = sprintf('bad_stim_%d', i);
                f = fullfile(tc.TmpDir, [name '.m']);
                fid = fopen(f, 'w');
                fprintf(fid, 'function s = %s()\n', name);
                fprintf(fid, 's.nouns = repmat({''n''}, 1, 48);\n');
                fprintf(fid, 's.relatedPairs = repmat({''a'',''b''}, 36, 1);\n');
                fprintf(fid, 's.unrelatedPairs = repmat({''c'',''d''}, 36, 1);\n');
                fprintf(fid, 's.activeSentences = repmat({''x ___.''}, 1, 48);\n');
                fprintf(fid, '%s\nend\n', bodies{i, 1}{1});
                fclose(fid);
                tc.verifyError(@() loadStimulusLists(LanguageMappingTest.cfg(), f), bodies{i, 2});
            end
        end

        % ---- logging / output --------------------------------------------
        function testDefaultRecordColumns(tc)
            % Column set and order of every log row / CSV.
            d = defaultRecord(LanguageMappingTest.cfg());
            expected = {'subjectID','sessionID','taskName','blockNumber','blockType', ...
                'trialNumber','stimulus','correctAnswer','participantResponse', ...
                'accuracy','reactionTime','eventName','eventOnsetGetSecs', ...
                'eventOnsetRelative','eventDuration','triggerCode'};
            tc.verifyEqual(fieldnames(d)', expected);
            tc.verifyEqual(d.subjectID, "test001");
            tc.verifyTrue(isnan(d.accuracy));
        end

        function testWriteAllCSVsAndSaveAll(tc)
            % One CSV per task with the defaultRecord columns; relative time derived.
            c = LanguageMappingTest.cfg();
            c.dataFolder = tc.TmpDir;
            c.sync = struct('tZeroGetSecs', 100, 'tZeroPosix', 0, 'tZeroClock', "", 'timeZone', "");
            logEvent(c, struct('taskName', "TaskA", 'eventName', "blockStart", 'eventOnsetGetSecs', 102.5));
            logEvent(c, struct('taskName', "TaskB", 'eventName', "stimOnset", 'eventOnsetGetSecs', 103, ...
                'stimulus', "NOUN01", 'triggerCode', 111));
            evalc('saveAll(c)');
            csvs = dir(fullfile(tc.TmpDir, '*_TaskA_*.csv'));
            tc.verifyNumElements(csvs, 1);
            tc.verifyNumElements(dir(fullfile(tc.TmpDir, '*_TaskB_*.csv')), 1);
            tc.verifyNumElements(dir(fullfile(tc.TmpDir, '*_combined_*.mat')), 1);
            tc.verifyNumElements(dir(fullfile(tc.TmpDir, '*_sync_*.txt')), 1);
            tc.verifyNumElements(dir(fullfile(tc.TmpDir, '*_subject_*.csv')), 1);
            T = readtable(fullfile(tc.TmpDir, csvs(1).name), 'TextType', 'string');
            tc.verifyEqual(T.Properties.VariableNames, fieldnames(defaultRecord(c))');
            tc.verifyEqual(T.eventOnsetRelative, 2.5, 'AbsTol', 1e-9);
        end

        % ---- Psychtoolbox licence key -----------------------------------
        function testLicenceKeyFromEnvironmentOnly(tc)
            % Key comes from PTB_LICENCE_KEY; none shipped, so missing -> '' + warning.
            old = getenv('PTB_LICENCE_KEY');
            tc.addTeardown(@() setenv('PTB_LICENCE_KEY', old));
            setenv('PTB_LICENCE_KEY', ' ABCDE-12345 ');
            tc.verifyEqual(ptbLicenceKey(), 'ABCDE-12345');
            setenv('PTB_LICENCE_KEY', '');
            tc.assumeFalse(exist(fullfile(tc.RepoRoot, 'helpers', 'ptb_licence_key.local.txt'), 'file') == 2, ...
                'a local key file is present on this machine');
            k = tc.verifyWarning(@ptbLicenceKey, 'ptbLicenceKey:missing');
            tc.verifyEmpty(k);
        end

        % ---- headless end-to-end schedule --------------------------------
        function testFullScheduleHeadless(tc)
            % All four tasks on the virtual clock: blocks, rests, triggers, timing.
            [c, T] = tc.simulate(LanguageMappingTest.cfg(), 1:4);
            names = ["VerbGeneration", "SemanticRelatedness", "PhonemicFluency", "SentenceCompletion"];
            trig = [101 102; 201 202; 301 302; 401 402];
            for i = 1:4
                S = T(T.taskName == names(i), :);
                B = S(S.eventName == "blockStart", :);
                tc.verifyEqual(height(B), 12, names(i));
                tc.verifyEqual(B.blockType', repmat(["active" "control"], 1, 6), names(i));
                tc.verifyEqual(B.triggerCode', repmat(trig(i, :), 1, 6), names(i));
                tc.verifyEqual(sum(S.eventName == "interRest"), 11, names(i));
                tc.verifyEqual(sum(S.eventName == "restStart"), 2, names(i));
                % block onsets 30 s apart (20 s block + 10 s rest); fluency adds
                % the 5 s typed check after each active block
                gaps = diff(B.eventOnsetGetSecs);
                if names(i) == "PhonemicFluency"
                    expectedGaps = repmat([35 30], 1, 6);
                    expectedGaps = expectedGaps(1:11)';
                else
                    expectedGaps = 30 * ones(11, 1);
                end
                tc.verifyEqual(gaps, expectedGaps, 'AbsTol', 0.1, names(i));
                R = S(S.eventName == "restStart", :);
                span = R.eventOnsetGetSecs(2) + c.restDuration - R.eventOnsetGetSecs(1);
                extra = 30 * (names(i) == "PhonemicFluency");
                % Rest screens are timed from the moment they are drawn (not on
                % a grid), so each adds one frame + poll granularity: ~0.2-0.4 s
                % over a task. Onsets are logged, so analysis is unaffected.
                tc.verifyEqual(span, 380 + extra, 'AbsTol', 0.5, names(i));
            end
            % trial counts
            tc.verifyEqual(sum(T.taskName == "VerbGeneration" & T.eventName == "stimOnset"), 48);
            tc.verifyEqual(sum(T.taskName == "SemanticRelatedness" & T.eventName == "stimOnset"), 72);
            tc.verifyEqual(sum(T.taskName == "SentenceCompletion" & T.eventName == "stimOnset"), 48);
            % active items come from this session's pickItems draw
            V = T(T.taskName == "VerbGeneration" & T.eventName == "stimOnset" & T.blockType == "active", :);
            tc.verifyEqual(sort(cellstr(V.stimulus)), sort(pickItems(c.t1.nouns, 24, c, 'verbgen'))');
            % semantic active: 18 related + 18 unrelated
            A = T(T.taskName == "SemanticRelatedness" & T.eventName == "stimOnset" & T.blockType == "active", :);
            tc.verifyEqual([sum(A.correctAnswer == "right") sum(A.correctAnswer == "left")], [18 18]);
            % no key presses simulated -> low-response warnings logged, no accuracy
            tc.verifyTrue(all(isnan(A.accuracy)));
        end

        function testDryRunScheduleHeadless(tc)
            % The dry-run design builds and runs end to end headless.
            c = config_language_mapping(struct('dryRun', true, 'useLocalStimuli', false));
            [~, T] = tc.simulate(c, 1:4);
            for n = ["VerbGeneration", "SemanticRelatedness", "PhonemicFluency", "SentenceCompletion"]
                tc.verifyEqual(sum(T.taskName == n & T.eventName == "blockStart"), 4, n);
                tc.verifyEqual(sum(T.taskName == n & T.eventName == "interRest"), 3, n);
            end
        end

        function testScheduleReproducible(tc)
            % Same subject/session -> identical schedule; other subject differs.
            [~, T1] = tc.simulate(LanguageMappingTest.cfg(), 1:4);
            ptbStubControl('reset');
            [~, T2] = tc.simulate(LanguageMappingTest.cfg(), 1:4);
            tc.verifyEqual(T1.stimulus, T2.stimulus);
            tc.verifyEqual(T1.correctAnswer, T2.correctAnswer);
            ptbStubControl('reset');
            [~, T3] = tc.simulate(LanguageMappingTest.cfg('subjectID', 'test002'), 1:4);
            tc.verifyNotEqual(T1.stimulus, T3.stimulus);
        end
    end
end
