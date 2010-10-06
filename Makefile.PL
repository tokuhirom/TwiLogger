use inc::Module::Install;
name 'TwiLogger';
all_from 'lib/TwiLogger.pm';

requires 'JSON' => 2.21;
requires 'MIME::Base64';
requires 'autodie';
requires 'Config::Tiny';
requires 'Try::Tiny';
requires 'AE' => 5.271;
requires 'Net::Twitter::Lite' => 0.10003;
requires 'AnyEvent::Twitter::Stream' => 0.20;

readme_markdown_from 'lib/TwiLogger.pm';
tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
test_requires 'YAML';
author_tests('xt');
# use_test_base;
auto_include;
WriteAll;
