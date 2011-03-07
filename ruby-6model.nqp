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
        my $new := pir::repr_type_object_for__PPs($metaclass, $repr);
        $new;
    }

    method add_parent($obj, $parent) {
        if $!virtual && $!parent_set {
            return $!parent.HOW.add_parent($!parent, $parent);
        }
        if $!parent_set {
            pir::die("RubyClassHOW does not support multiple inheritance.");
        }
        $!parent := $parent;
        $!parent_set := 1;
    }

    method add_method($obj, $name, $code_obj) {
        if %!methods{$name} {
            pir::die("This class (" ~ $obj.HOW.name() ~ ") already has a method named " ~ $name);
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
        #if !$!parent_set && $!name ne 'RubyObject' {
            #    $!parent := RubyObject;
            #$!parent_set := 1;
            #}
        # Compose attributes.
        for self.attributes($obj, :local<0> ) { $_.compose($obj) }
        if $!virtual {
            $!parent.HOW.compose($!parent);
        }
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
        return $!name;
    }

    method set_name($obj, $name) {
        $!name := $name;
    }

    method attributes($obj, :$local!) {
        my @attrs;
        for %!attributes {
            @attrs.push($_.value);
        }
        return @attrs
    }

    method parents($obj, :$local) {
        say("» " ~ $!name ~ "::parents");
        my @parents := [];
        if $!parent_set {
            if $local {
                @parents.unshift($!parent);
            }
            else {
                @parents := $!parent.HOW.parents($!parent);
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
        say("» " ~ $!name ~ "." ~ $name);
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

my $rc := RubyClassHOW.new_type(:name('RubyClass'));
pir::set_hll_global__vSP('RubyClass', $rc);

my $new := method (*@args) {
    say("» Constructing a " ~ self.HOW.name());
    my $single := RubyClassHOW.new_type(:virtual(1));
    #my $single := pir::repr_instance_of__PP(self);
    $single.HOW.add_parent($single, self);
    my $new := pir::repr_instance_of__PP($single);
    $new.initialize(|@args);
    return $new;
};
RubyClass.HOW.add_method(RubyClass, 'new', $new);
my $init := method ($super?) {
    if $super {
        self.HOW.add_parent(self,$super)
    }
};
RubyClass.HOW.add_method(RubyClass, 'initialize', $init);

my $cm := method () {
    say("Should only be callable on classes");
};
RubyClass.HOW.add_method(RubyClass, 'classmethod', $cm);

#say("Making rubyobject");
#my $ro := RubyClass.new();
#pir::set_hll_global__vSP('RubyObject', $ro);
#RubyObject.HOW.set_name(RubyObject, 'RubyObject');
#RubyClass.HOW.add_parent(RubyClass, RubyObject);

RubyClass.HOW.compose(RubyClass);
say("RubyClass composed");

#$init := method () {
#};
#RubyObject.HOW.add_method(RubyObject, 'initialize', $init);
#RubyObject.HOW.compose(RubyObject);
# -------------

say("Making Cow");
my $t := RubyClass.new();
$t.HOW.set_name($t, 'Cow');
pir::set_hll_global__vSP('Cow', $t);
say("Cow instantiated");
my $h := $t.HOW;
$h.add_attribute($t, NQPAttribute.new(:name('@noise')));
#Cow.HOW.add_parent(Cow, RubyObject);
$init := method ($noise) {
    pir::setattribute__vPPsP(self, Cow, '@noise', $noise);
};
$h.add_method($t, 'initialize', $init);
my $speak := method ($self:) { say(pir::getattribute__ppps($self, $t, '@noise')); }
$h.add_method($t, 'speak', $speak);
$h.compose($t);

say("Cow composed");
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
$b.classmethod;
