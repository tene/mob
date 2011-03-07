knowhow RubyClassHOW {
    has $!parent;
    has $!parent_set;
    has $!name;
    has %!methods;
    has %!attributes;
    has $!virtual;

    method new(:$name, :$virtual) {
        my $obj := pir::repr_instance_of__PP(self);
        $obj.BUILD(:name($name), :virtual($virtual));
        $obj
    }

    method BUILD(:$name, :$virtual) {
        $!name       := $name;
        $!parent_set := 0;
        $!virtual    := $virtual;
    }

    method new_type(:$name = '<anon>', :$repr = 'P6opaque', :$virtual = 0) {
        my $metaclass := self.new(:name($name), :virtual($virtual));
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
        if !$!parent_set && $!name ne 'RubyObject' {
            $!parent := RubyObject;
            $!parent_set := 1;
        }
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
        if $!parent_set {
            pir::die("RubyClassHOW does not support multiple inheritance.");
        }
        $!parent := $parent;
        $!parent_set := 1;
    }

    method parents($obj, :$local) {
        my @parents := [];
        if $!parent_set {
            if $local {
                @parents.unshift($!parent);
            }
            else {
                @parents := $!parent.HOW.parents($obj);
                @parents.unshift($!parent);
            }
        }
        @parents.unshift($obj.WHAT) unless $local;
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

# ------------

#rubyclass RubyObject {
#    method new (*%attrs) {
#        my $i := pir::repr_instance_of__PP(self);
#        for $i.HOW.parents($i) -> $cl {
#            $i.build-magic($cl, |%attrs);
#        }
#        return $i;
#    }
#    method build-magic ($type, *%attrs) {
#        for $type.HOW.attributes($type, :local) {
#            my $name := $_.name;
#            my $key := pir::substr__ssi($name, 2);
#            if pir::exists(%attrs, $key) {
#                pir::setattribute__vPPsP(self, $type, $name, %attrs{$key});
#            }
#        }
#        return self;
#    }
#}

# ------------

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
pir::set_hll_global__vSP('RubyObject', $t);
my $h := $t.HOW;
my $new := method (*@attrs) {
    my $single := self.HOW.new_type(:virtual(1));
    $single.HOW.add_parent($single,self);
    $single.HOW.compose($single);
    my $i := pir::repr_instance_of__PP($single);
    $i.initialize(|@attrs);
    return $i;
};
$h.add_method($t, 'new', $new);
my $init := method () {
};
$h.add_method($t, 'initialize', $init);
$h.compose(t);

# -------------

$t := RubyClassHOW.new_type(:name('Cow'));
pir::set_hll_global__vSP('Cow', $t);
$h := $t.HOW;
$h.add_attribute($t, NQPAttribute.new(:name('@noise')));
$init := method ($noise) {
    pir::setattribute__vPPsP(self, Cow, '@noise', $noise);
};
$h.add_method($t, 'initialize', $init);
my $speak := method ($self:) { say(pir::getattribute__ppps($self, $t, '@noise')); }
$h.add_method($t, 'speak', $speak);
$h.compose($t);

# -------------

my $a := Cow.new("mooooooo");
$a.speak;
my $b := Cow.new("mooooooo");
$b.speak;

my $greet := method () {
    say("ohai");
};
$a.HOW.add_method($a.WHAT, 'greet', $greet);
$a.greet;
$b.greet;
