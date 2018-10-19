package JSON::Transform;

use 5.014;
use strict;
use warnings;

=head1 NAME

JSON::Transform - arbitrary transformation of JSON-able data

=cut

our $VERSION = '0.01';

=begin markdown

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/mohawk2/json-transform.svg?branch=master)](https://travis-ci.org/mohawk2/json-transform) |

[![CPAN version](https://badge.fury.io/pl/JSON-Transform.svg)](https://metacpan.org/pod/JSON::Transform) [![Coverage Status](https://coveralls.io/repos/github/mohawk2/json-transform/badge.svg?branch=master)](https://coveralls.io/github/mohawk2/json-transform?branch=master)

=end markdown

=head1 SYNOPSIS

  use JSON::Transform qw(parse_transform);
  use JSON::MaybeXS;
  my $transformer = parse_transform(from_file($transformfile));
  to_file($outputfile, encode_json $transformer->(decode_json $json_input));

=head1 DESCRIPTION

Implements a language concisely describing a set of
transformations from an arbitrary JSON-able piece of data, to
another one. The description language uses L<JSON Pointer (RFC
6901)|https://tools.ietf.org/html/rfc6901> for addressing. JSON-able
means only strings, booleans, nulls (Perl C<undef>), numbers, array-refs,
hash-refs, with no circular references.

A transformation is made up of an output expression, which can be composed
of sub-expressions.

For instance, to transform an array of hashes that each have an C<id>
key, to a hash mapping each C<id> to its hash:

  # [ { "id": 1, "name": "Alice" }, { "id": 2, "name": "Bob" } ]
  # ->
  "" <@ { "/$K/id":$V-`id` }
  # ->
  # { "1": { "name": "Alice" }, "2": { "name": "Bob" } }

While to do the reverse transformation:

  "" <% [ $V+`id`:$K ]

The identity for an array:

  "" <@ [ $V ]

The identity for an object/hash:

  "" <% { $K:$V }

To move from one part of a structure to another:

  "/destination" << "/source"

To copy from one part of a structure to another:

  "/destination" <- "/source"

To do the same with a transformation (assumes C</source> is an array
of hashes):

  "/destination" <- "/source" <@ [ $V+`order`:$K ]

To bind a variable, then replace the whole data structure:

  $defs <- "/definitions"
  "" <- $defs

=head2 Expression types

=over

=item Object/hash

These terms are used here interchangeably.

=item Array

=item String

=item Integer

=item Float

=item Boolean

=item Null

=back

=head2 JSON pointers

JSON pointers are surrounded by C<"">. JSON pointer syntax gives special
meaning to the C<~> character, as well as to C</>. To quote a C<~>,
say C<~0>. To quote a C</>, say C<~1>. Since a C<$> has special meaning,
to use a literal one, quote it with a preceding C<\>.

The output type of a JSON pointer is whatever the pointed-at value is.

=head2 Transformations

A transformation has a destination, a transformation type operator, and
a source-value expression. The destination can be a variable to bind to,
or a JSON pointer.

If the source-value expression has a JSON-pointer source, then the
destination can be omitted and the JSON-pointer source will be used.

The output type of the source-value expression can be anything.

=head3 Transformation operators

=over

=item C<<< <- >>>

Copying (including assignment for variable bindings)

=item C<<< << >>>

Moving - error if the source-value is other than a bare JSON pointer

=back

=head2 Destination value expressions

These can be either a variable, or a JSON pointer.

=head3 Variables

These are expressed as C<$> followed by a lower-case letter, followed
by zero or more letters.

=head2 Source value expressions

These can be either a single value including variables, of any type,
or a mapping expression.

=head2 String value expressions

String value expressions can be surrounded by C<``>. They have the same
quoting rules as in JSON's C<">-surrounded strings, including quoting
of C<`> using C<\>. Any value inside, including variables, will be
concatenated in the obvious way, and numbers will be coerced into strings
(be careful of locale). Booleans and nulls will be stringified into
C<[true]>, C<[false]>, C<[null]>.

=head2 Mapping expressions

A mapping expression has a source-value, a mapping operator, and a
mapping description.

The mapping operator is either C<<< <@ >>>, requiring the source-value
to be of type array, or C<<< <% >>>, requiring type object/hash. If the
input data pointed at by the source value expression is not the right
type, this is an error.

The mapping description must be surrounded by either C<[]> meaning return
type array, or C<{}> for object/hash.

The description will be evaluated once for each input value.
Within the brackets, C<$K> and C<$V> will have special meaning.

For an array input, each input will be each single array value, and C<$K>
will be the zero-based array index.

For an object/hash input, each input will be each pair. C<$K> will be
the object key being evaluated, of type string.

In either case, C<$V> will be the relevant value, of whatever type from
the input. C<$C> will be of type integer, being the number of inputs.

=head3 Mapping to an object/hash

The return value will be of type object/hash, composed of a set of pairs,
expressed within C<{}> as:

=over

=item a expression of type string

=item C<:>

=item an expression of any type

=back

=head3 Mapping to an array

Within C<[]>, the value expression will be an arbitrary value expression.

=head2 Single-value modifiers

A single value can have a modifier, followed by arguments.

=head3 C<+>

The operand value must be of type object/hash.
The argument must be a pair of string-value, C<:>, any-value.
The return value will be the object/hash with that additional key/value pair.

=head3 C<->

The operand value must be of type object/hash.
The argument must be a string-value.
The return value will be the object/hash without that key.

=head2 Comments

Any C<#> character up to the end of that line will be a comment,
and ignored.

=head1 DEBUGGING

To debug, set environment variable C<JSON_TRANSFORM_DEBUG> to a true value.

=head1 EXPORT

=head2 parse_transform

On error, throws an exception. On success, returns a function that can
be called with JSON-able data, that will either throw an exception or
return the transformed data.

Takes arguments:

=over

=item $input_text

The text describing the transformation.

=back

=head1 SEE ALSO

L<Pegex>

L<RFC 6902 - JSON Patch|https://tools.ietf.org/html/rfc6902> - intended
to change an existing structure, leaving it (largely) the same shape

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests on
L<https://github.com/mohawk2/json-transform/issues>.

Or, if you prefer email and/or RT: to C<bug-json-transform
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSON-Transform>. I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Ed J.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
