% $helpers->assets->require('/autosize/jquery.autosize.min.js');
% $helpers->assets->require('/js/autosize.js');
% $helpers->assets->require('/js/quick-reply.js');
% $helpers->meta->set(title => loc('Update thread'));

<div class="grid-100">

    <h1><%= loc('Update thread') %></h1>

    <form method="POST" id="update-thread">

    <%== $helpers->form->input('title', label => loc('Title'), default => $thread->{title}) %>
    <%== $helpers->form->input('tags', label => loc('Tags'), default => $thread->{tags_list}) %>
    <%== $helpers->form->textarea('content', label => loc('Content'), default => $thread->{content}) %>

    <input type="submit" value="<%= loc('Update') %>" />

    %== $helpers->displayer->render('include/markup-help-button');

    </form>

    %== $helpers->displayer->render('include/markup-help');

</div>
