use strict;
use warnings;

use Test::More;
use TestLib;
use TestRequest;
use TestDB;

use Threads::Helper::Thread;

subtest 'finds similar threads' => sub {
    TestDB->setup;

    my $thread = TestDB->create(
        'Thread',
        user_id => 1,
        tags    => [{title => 'foo'}, {title => 'bar'}]
    );
    TestDB->create(
        'Thread',
        user_id => 1,
        tags    => [{title => 'foo'}, {title => 'baz'}]
    );
    TestDB->create(
        'Thread',
        user_id => 1,
        tags    => [{title => 'foo'}, {title => 'qux'}]
    );

    my $helper = _build_helper();

    my @similar = $helper->similar({id => $thread->id});

    is @similar, 2;
};

subtest 'returns empty when no tags' => sub {
    TestDB->setup;

    my $thread = TestDB->create('Thread', user_id => 1);

    my $helper = _build_helper();

    my @similar = $helper->similar({id => $thread->id});

    is @similar, 0;
};

my $env;

sub _build_helper {
    my (%params) = @_;

    $env = $params{env} || TestRequest->to_env(%params);

    Threads::Helper::Thread->new(env => $env);
}

done_testing;
