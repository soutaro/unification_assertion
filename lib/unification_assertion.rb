require "unification_assertion/version"

require "minitest/unit"

module UnificationAssertion
  include MiniTest::Assertions

  module_function
  
  @@comparators = {}

  @@comparators[Array] = lambda {|a, b, eqs, unifier, path, block|
    block.call(a.length, b.length, path + ".length")
    a.zip(b).each.with_index do |pair, index|
      pair << path + "[#{index}]"
      eqs << pair
    end
    eqs
  }

  @@comparators[Hash] = lambda {|a, b, eqs, unifier, path, block|
    block.call(a.keys.sort, b.keys.sort, path + ".keys.sort")
    eqs.concat(a.keys.map {|key| [a[key], b[key], path+"[#{key.inspect}]"] })
  }

  # Comparators are hash from a class to its comparator.
  # It is used to check unifiability of two object of the given hash.
  #
  # There are two comparators defined by default; for |Array| and |Hash|.
  #
  # == Example ==
  #   UnificationAssertion.comparators[Array] = lambda do |a, b, message, eqs, unifier, &block|
  #     block.call(a.length, bl.ength, message + " (Array length mismatch)")
  #     eqs.concat(a.zip(b))
  #   end
  #
  # This is our comparator for |Array|. It first tests if the length of the two arrays are equal.
  # And then, it pushes the equations of each components of the arrays.
  # The components of the arrays will be tested unifiability later.
  #
  # == Comparator ==
  #
  # Comparator is a lambda which takes 5 arguments and block and checks the unifiability
  # of the first two arguments.
  #
  # * |a|, |b|   Objects they are compared.
  # * |message|  Message given to |unify|.
  # * |eqs|      Equations array. This is for output.
  # * |unifier|  Current unifier. This is just for reference.
  # * |&block|   Block given to |unify|, which can be used to check the equality of two values.
  # 
  def comparators
    @@comparators
  end
  
  # Run unification algorithm for given equations.
  # If all equations in |eqs| are unifiable, |unify| returns (the most-general) unifier.
  # 
  # Which identifies an symbol as a meta variable if the name matches with |options[:meta_pattern]|.
  # The default of the meta variable pattern is |/^_/|.
  # For example, |:_a| and |:_xyz| are meta variable, but |:a| and |:hello_world| are not.
  #
  # It also accepts wildcard variable. Which matches with any value, but does not introduce new equational constraints.
  # The default wildcard is |:_|.
  #
  # |unify| takes a block to test equation of two values.
  # The simplest form should be using |assert_equal|, however it can be customized as you like.
  #
  # == Example ==
  #   unify([[:_a, 1], [{ :x => :_b, :y => 1 }, { :x => 3, :y => 1 }]], "Example!!") do |x, y, message|
  #     assert_equal(x,y,message)
  #   end
  #
  # The |unify| call will return an hash |{ :_a => 1, :_b => 3 }|.
  # The block will be used to test equality between 1 and 1 (it will pass.)
  #
  def unify(eqs, unifier = {}, options = {}, &block)
    options = { :meta_pattern => /^_/, :wildcard => :_ }.merge!(options)
    
    pattern = options[:meta_pattern]
    wildcard = options[:wildcard]
    
    while eq = eqs.shift
      a,b,path = eq
      case
      when (Symbol === a and a.to_s =~ pattern)
        unless a == wildcard
          eqs = substitute({ a => b }, eqs)
          unifier = substitute({ a => b }, unifier).merge!(a => b)
        end
      when (Symbol === b and b.to_s =~ pattern)
        unless b == wildcard
          eqs = substitute({ b => a }, eqs)
          unifier = substitute({ b => a }, unifier).merge!(b => a)
        end
      when (a.class == b.class and @@comparators[a.class])
        @@comparators[a.class].call(a, b, eqs, unifier, path, block)
      else
        yield(a, b, path)
      end
    end
    
    unifier.inject({}) {|acc, (key, value)|
      if key == value
        acc
      else
        acc.merge!(key => value)
      end
    }
  end

  @@substituters = {}
  @@substituters[Hash] = lambda {|unifier, hash|
    hash.inject({}) {|acc, (key, val)|
      if unifier[val]
        acc.merge!(key => unifier[val])
      else
        acc.merge!(key => substitute(unifier, val))
      end
    }
  }
  @@substituters[Symbol] = lambda {|unifier, symbol| unifier[symbol] or symbol }
  @@substituters[Array] = lambda {|unifier, array|
    array.map {|x| substitute(unifier, x) }
  }

  def substitutions
    @@substituters
  end
  
  def substitute(unifier, a)
    subst = @@substituters[a.class]
    if subst
      subst.call(unifier, a)
    else
      a
    end
  end
  
  # Run unification between |a| and |b|, and fails if they are not unifiable.
  # |assert_unifiable| can have block, which yields the unifier for |a| and |b| if exists.
  # 
  def assert_unifiable(a, b, original_message = "", options = {}, &block)
    msg = proc {|eq, path|
      header = if original_message == nil or original_message.length == 0
            original_message
          else
            "No unification"
          end

      footer = "\nCould not find a solution of equation at it#{path}.\n=> #{mu_pp(eq[0])} == #{mu_pp(eq[1])}"

      message(header, footer) {
        a_pp = mu_pp(a)
        b_pp = mu_pp(b)

        "=> #{a_pp}\n=> #{b_pp}"
      }
    }

    unifier = unify([[a, b, ""]], {}, options) do |x, y, path|
      assert(x==y, msg.call([x, y], path))
    end

    if block
      yield(unifier)
    end
  end
end

