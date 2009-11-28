#! /usr/local/bin/parrot

=head1 NAME

setup.pir - Python distutils style

=head1 DESCRIPTION

No Configure step, no Makefile generated.

=head1 USAGE

    $ parrot setup.pir build
    $ parrot setup.pir test
    $ sudo parrot setup.pir install

=cut

.sub 'main' :main
    .param pmc args
    $S0 = shift args
    load_bytecode 'distutils.pbc'

    .const 'Sub' prebuild = 'prebuild'
    register_step_before('build', prebuild)

    .const 'Sub' clean = 'clean'
    register_step_before('clean', clean)

    $P0 = new 'Hash'
    $P0['name'] = 'Steme'
    $P0['abstract'] = 'Scheme for Parrot'
    $P0['authority'] = 'http://github.com/tene'
    $P0['description'] = 'Scheme for Parrot'
    $P1 = split ';', 'scheme;lisp'
    $P0['keywords'] = $P1
#    $P0['license_type'] = ''
#    $P0['license_uri'] = ''
    $P0['copyright_holder'] = 'Stephen Weeks'
    $P0['checkout_uri'] = 'git://github.com/tene/steme.git'
    $P0['browser_uri'] = 'http://github.com/tene/steme'
    $P0['project_uri'] = 'http://github.com/tene/steme'

    # build
    $P2 = new 'Hash'
    $P2['src/gen_grammar.pir'] = 'src/pct/grammar.pg'
    $P2['src/gen_actions.pir'] = 'src/pct/actions.pm'
    $P0['pir_nqp-rx'] = $P2

    $P3 = new 'Hash'
    $P4 = split "\n", <<'SOURCES'
steme.pir
src/gen_grammar.pir
src/gen_actions.pir
src/gen_builtins.pir
SOURCES
    $S0 = pop $P4
    $P3['steme.pbc'] = $P4
    $P0['pbc_pir'] = $P3

    $P5 = new 'Hash'
    $P5['parrot-steme'] = 'steme.pbc'
    $P0['installable_pbc'] = $P5

    # test
    $S0 = get_parrot()
    $S0 .= ' steme.pbc'
    $P0['prove_exec'] = $S0

    .tailcall setup(args :flat, $P0 :flat :named)
.end

.sub 'prebuild' :anon
    .param pmc kv :slurpy :named

    $P1 = split "\n", <<'BUILTINS_PIR'
src/builtins/say.pir
src/builtins/math.pir
src/builtins/cmp.pir
src/builtins/library.pir
src/builtins/control.pir
BUILTINS_PIR
    $S0 = pop $P1
    $I0 = newer('src/gen_builtins.pir', $P1)
    if $I0 goto L1
    $S0 = "# generated by setup.pir\n\n.include '"
    $S1 = join "'\n.include '", $P1
    $S0 .= $S1
    $S0 .= "'\n\n"
    $P0 = new 'FileHandle'
    $P0.'open'('src/gen_builtins.pir', 'w')
    $P0.'puts'($S0)
    $P0.'close'()
    say "creating src/gen_builtins.pir"
  L1:
.end

.sub 'clean' :anon
    .param pmc kv :slurpy :named
    unlink('src/gen_builtins.pir')
.end


# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
