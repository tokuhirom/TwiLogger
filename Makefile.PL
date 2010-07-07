use inc::Module::Install;
name 'TwiLogger';
all_from 'lib/TwiLogger.pm';

# requires '';


readme_markdown_from 'lib/TwiLogger.pm';
tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
test_requires 'YAML';
author_tests('xt');
# use_test_base;
auto_include;
WriteAll;