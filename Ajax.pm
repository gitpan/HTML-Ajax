package HTML::Ajax;

use strict;
use base 'Class::Accessor::Fast';

our $VERSION = '0.02';
our $ajax    = do { local $/; <DATA> };

=head1 NAME

HTML::Ajax - Generate HTML and Javascript for Ajax

=head1 SYNOPSIS

    use HTML::Ajax;

    my $ajax = HTML::Ajax->new;
    print $ajax->library;
    print $ajax->form_tag( $id, $url, $update );
    print $ajax->observe_field( $id, $url, $frequency, $update, $param );
    print $ajax->observe_form( $id, $url, $frequency, $update );
    print $ajax->link_to( $url, $text, $update );
    print $ajax->link_field( $id, $url, $text, $update, $param );

=head1 DESCRIPTION

Some stuff to make Ajax fun.
It's just a good beginning, more little helpers will come soon.

=head2 METHODS

=head3 $ajax->library

Returns our library of Javascript functions and objects, in a script block.

=cut

sub library {
    my $self = shift;
    my $out  = $self->raw_library;
    return qq|<script type="text/javascript">\n<!--\n$out\n//-->\n</script>|;
}

=head3 $ajax->form_tag( $id, $url, $update )

Returns a opening form tag using ajax instead of POST.

    id     = DOM id for form
    url    = url to request
    update = DOM id to change innerHTML with responseText

=cut

sub form_tag {
    my ( $self, $id, $uri, $update ) = @_;
    die 'Form id needed!' unless $id;
    die 'URI needed!'     unless $uri;
    return <<"EOF";
<form id="$id" action="javascript:submitForm( '$id', '$uri', '$update' )">
EOF
}

=head3 $ajax->observe_field( $id, $url, $frequency, $update, $param )

Observes a field and makes a request for changes.

    id        = DOM id of field to observe
    url       = url to request
    frequency = frequency for observation (defaults to 2)
    update    = DOM id to change innerHTML with responseText
    param     = name of parameter for request (defaults to value)

=cut

sub observe_field {
    my ( $self, $id, $uri, $freq, $update, $param ) = @_;
    die 'Field id needed!' unless $id;
    die 'URI needed!'      unless $uri;
    $freq  ||= 2;
    $param ||= 'value';
    return <<"EOF";
<script type="text/javascript">
<!--
observeField( '$id', '$uri', $freq, '$update', '', '$param' );
//-->
</script>
EOF
}

=head3 $ajax->observe_form( $id, $url, $frequency, $update )

Observes a whole form with all fields and makes a request for changes.

    id        = DOM id of form to observe
    url       = url to request
    frequency = frequency for observation (defaults to 2)
    update    = DOM id to change innerHTML with responseText

=cut

sub observe_form {
    my ( $self, $id, $uri, $freq, $update ) = @_;
    die 'Form id needed!' unless $id;
    die 'URI needed!'     unless $uri;
    $freq ||= 2;
    return <<"EOF";
<script type="text/javascript">
<!--
observeForm( '$id', '$uri', $freq, '$update', '' );
//-->
</script>
EOF
}

=head3 $ajax->link_to( $url, $text, $update )

Creates a link that makes a request when pressed.

    url    = url to request
    text   = link text or html
    update = DOM id to change innerHTML with responseText

=cut

sub link_to {
    my ( $self, $uri, $text, $update ) = @_;
    die 'URL needed!' unless $uri;
    $update ||= '';
    return <<"";
<a href="javascript:linkTo( '$uri', '$update' );">$text</a>

}

=head3 $ajax->link_field( $id, $url, $text, $update, $param )

Creates a link that submits a field value when pressed.

    id     = DOM id of field to observe
    url    = url to request
    text   = link text or html
    update = DOM id to change innerHTML with responseText
    param  = name of parameter for request (defaults to value)

=cut

sub link_field {
    my ( $self, $id, $uri, $text, $update, $param ) = @_;
    die 'Field id needed!' unless $id;
    die 'URL needed!'      unless $uri;
    $update ||= '';
    $param  ||= 'value';
    return <<"";
<a href="javascript:linkTo( '$id', '$uri', '$update', '$param' );">$text</a>

}

=head3 $ajax->raw_library

Returns our library of Javascript functions and objects.

=cut

sub raw_library { return $ajax }

=head1 SEE ALSO

L<Catalyst::Plugin::Ajax>, L<Catalyst>.

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

Based on the work of Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
__DATA__
var AJAX_SUCCESS         = 0;
var AJAX_INVALIDOBJECT   = 1;
var AJAX_INVALIDCALLBACK = 2;
var AJAX_FAILEDOPEN      = 3;

function Ajax () {
    this.version       = '0.01';
    this.isAsync       = false;
    this.agent         = null;
    this.lastException = '';

    if( typeof XMLHttpRequest != 'undefined' )
        this.agent = new XMLHttpRequest();

    if( this.agent == null ) {

        var axos = new Array(
            'MSXML2.XMLHTTP.4.0',
            'MSXML2.XMLHTTP.3.0',
            'MSXML2.XMLHTTP',
            'Microsoft.XMLHTTP'
        );

        for( var i = 0; this.agent == null && i < axos.length; i++ ) {
            try {
                this.agent = new ActiveXObject(axos[i]);
            } catch(e) {
                this.lastException = e;
                this.agent         = null;
            }
        }
    }

   this.isValid  = callAjaxIsValid;
   this.get      = callAjaxGet;
   this.post     = callAjaxPost;
   this.open     = callAjaxOpen;
   this.request  = callAjaxRequest;
   this.response = callAjaxResponse;
}

function AjaxResponse() {
    this.status     = 0;
    this.statusText = '';
    this.headers    = new Array();
    this.body       = '';
    this.text       = '';
    this.xml        = '';
}

function AjaxRequest() {
    this.method   = 'GET';
    this.url      = '';
    this.headers  = new Array();
    this.body     = null;
    this.callback = null;
}

function callAjaxGet( url, callback, headers ) {
    return this.open( 'GET', url, null, callback, headers );
}

function callAjaxIsValid() {
    return this.agent != null;
}

function callAjaxOpen( method, url, data, callback, headers ) {
    if (this.isValid()) {
        if (!method)  method       = 'GET';
        if (!data)    data         = null;
        if (callback) this.isAsync = true;

        if (this.isAsync) {
            if ( typeof callback != 'function' )
                return AJAX_INVALIDCALLBACK;
            this.agent.onreadystatechange = callback;
        }

        try {
            this.agent.open( method, url, this.isAsync );
        } catch(e) {
            this.lastException = e;
            return AJAX_FAILEDOPEN;
        }

        if ( method == 'POST' ) {
            this.agent.setRequestHeader( 'Connection', 'close' );
            this.agent.setRequestHeader( 'Content-type',
              'application/x-www-form-urlencoded' );
        }

        if ( headers != null ) {
            for ( var header in headers ) {
                this.agent.setRequestHeader( header, headers[header] );
            }
        }

        this.agent.send(data);
        return AJAX_SUCCESS;
    }
    return AJAX_INVALIDOBJECT;
}

function callAjaxPost( url, data, callback, headers ) {
    return this.open( 'POST', url, data, callback, headers );
}

function callAjaxResponse() {
    if ( this.agent.readyState != 4 )
        return null;

    var res = new AjaxResponse();

    res.status      = this.agent.status;
    res.statusText  = typeof this.agent.statusText == 'undefined'
        ? ''
        : this.agent.statusText;
    res.body        = typeof this.agent.responseBody == 'undefined'
        ? ''
        : this.agent.responseBody;
    res.text        = typeof this.agent.responseText == 'undefined'
        ? ''
        : this.agent.responseText;
    res.xml          = this.agent.responseXML == null
        ? ''
        : this.agent.responseXML;

    var string = this.agent.getAllResponseHeaders();
    if (!string) string = '';

    var lines = string.split("\\n");
    for ( var i = 0; i < lines.length; i++ ) {
        var header = lines[i].split(": ");
        if(header.length >= 2) {
            var headername  = header.shift();
            var headervalue = header.join(": ");

            res.headers[headername] = headervalue;
        }
    }

    return res;
}

function callAjaxRequest(req) {
   return this.Open(
       req.method,
       req.url,
       req.body,
       req.callback,
       req.headers
   );
}

function observeField ( field, uri, freq, update, value, param ) {
    var current_value = document.getElementById(field).value;
    if ( value != current_value) {
        var ajax = new Ajax();
        ajax.post(
            uri,
            encodeURIComponent(param) + '=' + encodeURIComponent(current_value),
            function () {
                var res = ajax.response();
                if ( res && res.status == 200 )
                    document.getElementById(update).innerHTML = res.text;
            }

        );
    }
    setTimeout(
        function() {
            observeField( field, uri, freq, update, current_value, param );
        },
        freq * 1000
    );
}

function serializeForm (form) {
    var elements = document.getElementById(form).elements;
    var fields = new Array();
    for ( var i = 0; i < elements.length; i++ ) {
        var element = elements[i];
        switch (element.type.toLowerCase()) {
            case 'hidden':
            case 'password':
            case 'text':
                fields.push( element.name + '=' + element.value );
            case 'checkbox':
            case 'radio':
                if (element.checked)
                    fields.push(
                        encodeURIComponent(element.name)
                        + '=' +
                        encodeURIComponent(element.value)
                    );
        }
    }
    return fields.join('&');
}

function observeForm ( form, uri, freq, update, value ) {
    var current_value = serializeForm(form);
    if ( value != current_value) {
        var ajax = new Ajax();
        ajax.post(
            uri,
            current_value,
            function () {
                var res = ajax.response();
                if ( update && res && res.status == 200 )
                    document.getElementById(update).innerHTML = res.text;
            }
        );
    }
    setTimeout(
        function() {
            observeForm( form, uri, freq, update, current_value );
        },
        freq * 1000
    );
}

function submitForm ( form, uri, update ) {
    var value = serializeForm(form);
    var ajax = new Ajax();
    ajax.post(
        uri,
        value,
        function () {
            var res = ajax.response();
            if ( update && res && res.status == 200 )
                document.getElementById(update).innerHTML = res.text;
        }
    );
}

function linkTo ( uri, update ) {
    var ajax = new Ajax();
    ajax.post(
        uri,
        '',
        function () {
            var res = ajax.response();
            if ( update && res && res.status == 200 )
                document.getElementById(update).innerHTML = res.text;
        }
    );
}

function linkField ( field, uri, update, param ) {
    var value = document.getElementById(field).value;
    var ajax = new Ajax();
    ajax.post(
        uri,
        encodeURIComponent(param) + '=' + encodeURIComponent(value),
        function () {
            var res = ajax.response();
            if ( update && res && res.status == 200 )
                document.getElementById(update).innerHTML = res.text;
        }
    );
}
