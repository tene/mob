knowhow RubyClassHOW {
    has $!parent;
    has $!name;
    has %!methods;
    has %!attributes;

    method new(:$name) {
        my $obj := pir::repr_instance_of__PP(self);
        $obj.BUILD(:name($name));
        $obj
    }

    method BUILD(:$name) {
        $!name := $name;
    }

    method new_type(:$name = '<anon>', :$repr = 'P6opaque') {
        my $metaclass := self.new(:name($name));
        pir::repr_type_object_for__PPs($metaclass, $repr);
    }

    method add_method($obj, $name, $code_obj) {
        if %!methods{$name} {
            pir::die("This class already has a method named " ~ $name);
        }
        %!methods{$name} := $code_obj;
    }

    method add_attribute($obj, $meta_attr) {
        my $name := $meta_attr.name;
        if %!attributes{$name} {
            pir::die("This class already has an attribute named " ~ $name);
        }
        %!attributes{$name} := $meta_attr;
    }

    method compose($obj) {
        $!parent := RubyObject unless $!name eq 'RubyObject' || pir::defined($!parent);
        # Compose attributes.
        for self.attributes($obj, :local<0> ) { $_.compose($obj) }
        $obj;
    }

    method methods($obj, :$local!) {
        my @meths;
        for %!methods {
            @meths.push($_.value);
        }
        return @meths
    }

    method method_table($obj) {
        return %!methods;
    }

    method name() {
        return $!name
    }

    method attributes($obj, :$local!) {
        my @attrs;
        for %!attributes {
            @attrs.push($_.value);
        }
        return @attrs
    }

    method add_parent($obj, $parent) {
        if pir::defined($!parent) {
            pir::die("RubyClassHOW does not support multiple inheritance.");
        }
        $!parent := $parent;
    }

    method parents($obj, :$local) {
        my @parents := [];
        if pir::defined($!parent) {
            if $local {
                @parents.unshift($!parent);
            }
            else {
                #@parents := $!parent.HOW.parents($obj);
                @parents.unshift($!parent);
            }
        }
        @parents.unshift($obj) unless $local;
        return @parents;
    }

    ##
    ## Dispatchy
    ##
    method find_method($obj, $name) {
        my @mro := $obj.HOW.parents($obj);
        for @mro {
            my %meths := $_.HOW.method_table($obj);
            my $found := %meths{$name};
            if pir::defined($found) {
                return $found;
            }
        }
        pir::null__P()
    }
}

#class Cow
#    def speak
#        puts "mooo"
#    end
#end
#
#c = Cow.new
#c.speak

# ------------
my $t := RubyClassHOW.new_type(:name('RubyObject'));
my $h := $t.HOW;
my $new := method (*%attrs) {
    my $i := pir::repr_instance_of__PP(self);
    for $i.HOW.parents($i) -> $cl {
        $i.build-magic($cl, |%attrs);
    }
    return $i;
};
$h.add_method($t, 'new', $new);
my $bm := method ($type, *%attrs) {
    for $type.HOW.attributes($type, :local) {
        my $name := $_.name;
        if pir::exists(%attrs, $name) {
            pir::setattribute__vPPsP(self, $type, $name, %attrs{$name});
        }
    }
    return self;
};
$h.add_method($t, 'build-magic', $bm);
pir::set_hll_global__vSP('RubyObject', $t);
$h.compose(t);

# -------------

$t := RubyClassHOW.new_type(:name('Cow'));
$h := $t.HOW;
$h.add_attribute($t, NQPAttribute.new(:name('$!noise')));
my $speak := method ($self:) { say(pir::getattribute__ppps($self, Cow, '$!noise')); }
$h.add_method($t, 'speak', $speak);
$h.compose($t);
pir::set_hll_global__vSP('Cow', $t);

# -------------

my $c := Cow.new(:noise("mooooooo"));
$c.speak;