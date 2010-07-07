use inc::Module::Install;
name 'TwiLogger';
all_from 'lib/TwiLogger.pm';
use 5.008001;

requires 'AnyEvent::HTTP';
requires 'AE';
requires 'Try::Tiny';
requires 'Config::Tiny';
requires 'MIME::Base64';
requires 'JSON';
requires 'autodie';

readme_markdown_from 'lib/TwiLogger.pm';
tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
test_requires 'YAML';
author_tests('xt');
# use_test_base;
auto_include;
WriteAll;
