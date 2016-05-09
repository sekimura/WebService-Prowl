use inc::Module::Install;
no strict "subs";
name 'WebService-Prowl';
all_from 'lib/WebService/Prowl.pm';

use_test_base;
auto_include_deps;
cpanfile;
author_tests('xt');
auto_set_repository;
WriteAll;
