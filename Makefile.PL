use inc::Module::Install;
no strict "subs";
name 'WebService-Prowl';
all_from 'lib/WebService/Prowl.pm';

requires 'LWP::UserAgent' => '6.02';
requires 'LWP::Protocol::https';
requires 'Carp';
requires 'XML::Simple';
requires 'URI::Escape';
requires 'AnyEvent::HTTP';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
