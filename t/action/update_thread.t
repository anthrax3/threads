use strict;
use warnings;

use Test::More;
use Test::Fatal;
use TestLib;
use TestDB;
use TestRequest;

use HTTP::Request::Common;
use Threads::DB::Tag;
use Threads::DB::User;
use Threads::DB::Thread;
use Threads::Action::UpdateThread;

subtest 'returns 404 when unknown thread' => sub {
    TestDB->setup;

    my $action = _build_action(captures => {});

    my $e = exception { $action->run };

    is $e->code, 404;
};

subtest 'returns 404 when wrong user' => sub {
    TestDB->setup;

    my $user = TestDB->create('User');
    my $thread = Threads::DB::Thread->new(user_id => 999)->create;

    my $action = _build_action(
        req       => POST('/' => {}),
        captures  => {id      => $thread->id},
        'tu.user' => $user
    );

    my $e = exception { $action->run };

    is $e->code, 404;
};

subtest 'set template var errors' => sub {
    TestDB->setup;

    my $user = TestDB->create('User');
    my $thread = Threads::DB::Thread->new(user_id => $user->id)->create;

    my $action = _build_action(
        req       => POST('/' => {}),
        captures  => {id      => $thread->id},
        'tu.user' => $user
    );

    $action->run;

    ok $action->scope->displayer->vars->{errors};
};

subtest 'updates thread with correct params' => sub {
    TestDB->setup;

    my $user   = TestDB->create('User');
    my $thread = Threads::DB::Thread->new(
        user_id => $user->id,
        title   => 'foo',
        content => 'bar'
    )->create;

    my $action = _build_action(
        req       => POST('/' => {title => 'bar', content => 'foo'}),
        captures  => {id      => $thread->id},
        'tu.user' => $user
    );

    $action->run;

    $thread->load;

    is $thread->title,     'bar';
    is $thread->content,   'foo';
    isnt $thread->updated, 0;
};

subtest 'updates editor id when other user' => sub {
    TestDB->setup;

    my $user  = TestDB->create('User');
    my $admin = TestDB->create(
        'User',
        name  => 'admin',
        email => 'admin@admin.com',
        role  => 'admin'
    );
    my $thread = Threads::DB::Thread->new(
        user_id => $user->id,
        title   => 'foo',
        content => 'bar'
    )->create;

    my $action = _build_action(
        req       => POST('/' => {title => 'bar', content => 'foo'}),
        captures  => {id      => $thread->id},
        'tu.user' => $admin
    );

    $action->run;

    $thread->load;

    is $thread->editor_id, $admin->id;
};

subtest 'updates thread tags' => sub {
    TestDB->setup;

    my $user   = TestDB->create('User');
    my $thread = Threads::DB::Thread->new(
        user_id => $user->id,
        title   => 'foo',
        content => 'bar'
    )->create;

    my $action = _build_action(
        req =>
          POST('/' => {title => 'bar', content => 'foo', tags => 'new,tags'}),
        captures  => {id => $thread->id},
        'tu.user' => $user
    );

    $action->run;

    my @tags = Threads::DB::Tag->find(order_by => [title => 'ASC']);

    is @tags, 2;
    is $tags[0]->title, 'new';
    is $tags[1]->title, 'tags';
};

subtest 'updates last_activity' => sub {
    TestDB->setup;

    my $user   = TestDB->create('User');
    my $thread = Threads::DB::Thread->new(
        user_id       => $user->id,
        title         => 'foo',
        content       => 'bar',
        last_activity => 123
    )->create;

    my $action = _build_action(
        req       => POST('/' => {title => 'bar', content => 'foo'}),
        captures  => {id      => $thread->id},
        'tu.user' => $user
    );

    $action->run;

    $thread->load;

    isnt $thread->last_activity, 123;
};

subtest 'redirects after update' => sub {
    TestDB->setup;

    my $user   = TestDB->create('User');
    my $thread = Threads::DB::Thread->new(
        user_id => $user->id,
        title   => 'foo',
        content => 'bar'
    )->create;

    my $action = _build_action(
        req       => POST('/' => {title => 'bar', content => 'foo'}),
        captures  => {id      => $thread->id},
        'tu.user' => $user
    );

    $action->mock('redirect');

    $action->run;

    my ($name) = $action->mocked_call_args('redirect');

    is $name, 'view_thread';
};

sub _build_action {
    my (%params) = @_;

    my $env = $params{env} || TestRequest->to_env(%params);

    my $action = Threads::Action::UpdateThread->new(env => $env);
    $action = Test::MonkeyMock->new($action);

    return $action;
}

done_testing;
