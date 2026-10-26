% RUN_TESTS  Run the headless test suite (no Psychtoolbox needed).
%
%   >> run tests/run_tests.m          % from the repository root
%   matlab -batch "run('tests/run_tests.m')"
%
% Errors (non-zero exit under -batch) if any test fails.

import matlab.unittest.TestRunner
import matlab.unittest.TestSuite

testDir = fileparts(mfilename('fullpath'));
suite   = TestSuite.fromFile(fullfile(testDir, 'LanguageMappingTest.m'));
runner  = TestRunner.withTextOutput('OutputDetail', 1);
results = runner.run(suite);
disp(table(results));
nFailed = sum([results.Failed]) + sum([results.Incomplete]);
disp([num2str(numel(results) - nFailed) ' of ' num2str(numel(results)) ' tests passed.']);
assert(nFailed == 0, 'run_tests:failed', 'Some tests failed.');
