use strict;
use warnings;

use Test2::Tools::Basic;
use Test2::API qw/intercept/;
use Test2::Tools::Compare qw/array event end is like/;
use Test2::Tools::Target 'Test2::Plugin::SRand';
use Test2::Tools::Warnings qw/warning/;

{
    local %ENV = %ENV;
    $ENV{HARNESS_IS_VERBOSE} = 1;
    $ENV{T2_RAND_SEED} = 1234;

    my $caller = [__PACKAGE__, __FILE__, __LINE__, 'xxx'];

    is(
        intercept { $CLASS->import('5555') },
        array {
            event Note => { message => "Seeded srand with seed '5555' from import arg." };
        },
        "got the event"
    );
    is($CLASS->seed, 5555, "set seed");
    is($CLASS->from, 'import arg', "set from");

    my ($events, $warning);
    $warning = warning { $events = intercept { $CLASS->import() } };

    is(
        $events,
        array {
            event Note => { message => "Seeded srand with seed '1234' from environment variable." };
        },
        "got the event"
    );
    is($CLASS->seed, 1234, "set seed");
    is($CLASS->from, 'environment variable', "set from");

    like(
        $warning,
        qr/SRand loaded multiple times, re-seeding rand/,
        "Warned about resetting srand"
    );

    delete $ENV{T2_RAND_SEED};
    $warning = warning { $events = intercept { $CLASS->import() } };

    like(
        $events,
        array {
            event Note => { message => qr/Seeded srand with seed '\d{8}' from local date\./ };
        },
        "got the event"
    );
    ok($CLASS->seed && $CLASS->seed != 1234, "set seed");
    is($CLASS->from, 'local date', "set from");

    like(
        $warning,
        qr/SRand loaded multiple times, re-seeding rand/,
        "Warned about resetting srand"
    );

    my $hooks = Test2::API::test2_list_exit_callbacks();
    delete $ENV{HARNESS_IS_VERBOSE};
    warning { $events = intercept { $CLASS->import() } };
    warning { $events = intercept { $CLASS->import() } };
    is(Test2::API::test2_list_exit_callbacks, $hooks + 1, "added hook, but only once");

    warning { $CLASS->import(undef) };
    is($CLASS->seed, 0 , "set seed");
    is($CLASS->from, 'import arg', "set from");
}

done_testing();
