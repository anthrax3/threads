package Threads::Action::UpdateThread;

use strict;
use warnings;

use parent 'Threads::Action::FormBase';

use Threads::ObjectACL;
use Threads::DB::Thread;

sub build_validator {
    my $self = shift;

    my $validator = $self->SUPER::build_validator;

    $validator->add_field('title');
    $validator->add_field('content');
    $validator->add_optional_field('tags');

    $validator->add_rule('title', 'Readable');
    $validator->add_rule('title', 'MaxLength', 255);

    $validator->add_rule('content', 'MaxLength', 5 * 1024);

    $validator->add_rule('tags', 'Tags');

    return $validator;
}

sub run {
    my $self = shift;

    my $thread_id = $self->captures->{id};

    return $self->throw_not_found
      unless my $thread = Threads::DB::Thread->new(id => $thread_id)->load;

    my $user = $self->scope->user;

    return $self->throw_not_found
      unless Threads::ObjectACL->new->is_allowed($user, $thread,
        'update_thread');

    $self->{thread} = $thread;

    $thread->related('tags');

    $self->set_var(thread => $thread->to_hash);

    return $self->SUPER::run;
}

sub submit {
    my $self = shift;
    my ($params) = @_;

    my $user = $self->scope->user;

    my $thread = $self->{thread};
    $thread->set_columns(%$params);
    $thread->updated(time);
    $thread->last_activity(time);
    $thread->editor_id($user->id);
    $thread->update;

    if ($params->{tags}) {
        my @tags = grep { $_ ne '' && /\w/ } split /\s*,\s*/, $params->{tags};

        if (@tags) {
            $thread->delete_related('tags');
            $thread->create_related('tags', title => $_) for @tags;
        }
    }

    return $self->redirect(
        'view_thread',
        id   => $thread->id,
        slug => $thread->slug
    );
}

1;
