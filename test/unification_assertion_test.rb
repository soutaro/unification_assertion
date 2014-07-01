require "minitest/autorun"
require "unification_assertion"

class UnificationAssertionTest < Minitest::Test
  include UnificationAssertion
  
  def call_unify(a, b)
    begin
      unifier = unify([[a,b,""]]) do |a, b|
        unless a == b
          raise "Failure"
        end
      end
      return unifier
    rescue
      nil
    end
  end

  def test_substitution
    subst = { :a => 1 }
    
    assert_equal 1, substitute(subst, :a)
    assert_equal :b, substitute(subst, :b)
    
    assert_equal "a", substitute(subst, "a")
    
    assert_equal [], substitute(subst, [])
    assert_equal [1], substitute(subst, [:a])
    assert_equal [:b], substitute(subst, [:b])

    assert_equal [[1]], substitute(subst, [[:a]])
    assert_equal [[:b]], substitute(subst, [[:b]])

    assert_equal({}, substitute(subst, {}))
    assert_equal({ x: 1 }, substitute(subst, { x: :a }))
    assert_equal({ x: :b}, substitute(subst, { x: :b }))
    
    assert_equal({ x: { y: 1 } }, substitute(subst, { x: { y: :a } }))
    assert_equal({ x: { y: :b } }, substitute(subst, { x: { y: :b } }))
  end

  def test_unify
    assert_nil call_unify(:a, :b)
    
    assert_equal({}, call_unify(:a, :a))
    
    assert_equal({ :_a => 1 }, call_unify(:_a, 1))
    assert_equal({ :_b => :a }, call_unify(:a, :_b))
    
    assert_equal({ :_a => [1,:_b,3] }, call_unify([1,:_b,3], :_a))
    assert_equal({}, call_unify([1,2,3], [1,2,3]))
    assert_nil call_unify([1,2,3], [1,3])
    assert_equal({ :_b => 2 }, call_unify([1,2,3], [1,:_b, 3]))
    assert_nil call_unify([1,2,3], [:_a, 2, :_a])

    assert_equal({}, call_unify({ a:1, b:2 }, { b:2, a:1 }))
    assert_equal({ :_a => 2 }, call_unify({ a:1, b: :_a }, { b:2, a:1 }))
    assert_equal({ :_b => :_a }, call_unify({ a: :_b, b: :_a }, { b: :_b, a: :_a }))
    assert_equal({ :_a => 1 }, call_unify([1, { :x => :_a }], [:_a, { :x => 1 }]))
    assert_nil call_unify([1, { :x => :_a }], [:_a, { :x => 2 }])
    assert_equal({ :_a => 1, :_b => 1},  call_unify([1, :_b], [:_a, :_a]))

    assert_equal({}, call_unify([:_, :_], [1,2]))
  end

  def test_assertion
    assert_unifiable(:_a, [1,2,3])
    
    assert_unifiable(:_a, 1) do |unifier|
      assert_equal 1, unifier[:_a]
    end

    # :_ is wildcard
    assert_unifiable([:_, :_, :_], [1,2,3])
    
    assert_unifiable({ :created_at => :_a,
                       :updated_at => :_b },
                     { :created_at => Time.now,
                       :updated_at => Time.now + 1 }) do |unifier|
      assert unifier[:_a] <= unifier[:_b]
    end

    # Meta variable pattern can be changed (ML type variable style)
    assert_unifiable([:"'a", :"'b", :"'_"], 
                     [1, 2, 3],
                     "Test message",
                     :meta_pattern => /^'/,
                     :wildcard => :"'_")
  end

  def test_assertion_failure
    # 1 and 3 is incompatible
    assert_raises(MiniTest::Assertion) do
      assert_unifiable([:_a, :_a], [1, 3])
    end

    # Time.now and Time.now+1 is incompatible
    assert_raises(MiniTest::Assertion) do
      assert_unifiable({ :created_at => :_a,
                         :updated_at => :_a },
                       { :created_at => Time.now,
                         :updated_at => Time.now + 1 })
    end
    
    # There is no ``row'' variable
    assert_raises(MiniTest::Assertion) do
      assert_unifiable([:_a, :_b], [1,2,3])
    end
    
    # There is no ``row'' variable
    assert_raises(MiniTest::Assertion) do
      assert_unifiable({ :_a => 3 }, { :x => :_b })
    end
  end

  def test_occur_check_skipped
    # This should be nil because of (absent) occur check will fail.
    # :_a \in FV( { :x => :_a } )  => cyclic!!
    #
    # However, I have not implement it.
    # This unification implementation is only for testing.
    # Who on the earth write this kind of test? (meaningless and it will result different from what the programmer expects)
    #
    assert_equal({ :_a => { :x => :_a }}, call_unify(:_a, { :x => :_a }))
  end
end
