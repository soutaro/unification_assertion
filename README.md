# UnificationAssertion

UnificationAssertion provides powerful and simple way to compare two
structures which may be different partialy. The comparison is based on
unification algorithm, which is used in Prolog implementations and
type inference algorithms.

The assertion will be like the following:

    assert_unifiable({ "timestamp" => :_,
                       "person" => {
                         "id" => :_,
                         "name" => "John",
                         "email" => "john@example.com",
                         "created_at" => :_a,
                         "updated_at" => :_a
                       }
                     }, JSON.parse(@response.body))

It compares two hash objects, but it does not care the exact value of
`"timestamp"`, `"id"`, `"created_at"`, and `"updated_at"`. The meta
variable `:_a` is not a black hole but test the equality between
`"created_at"` and `"updated_at"`.

## Introduction

I have been writing some tests like the following Rails functional
tests.

    # Testing a web api which create a person data and send the created person object as JSON
    post(:create_person, { :person => { :name => "John", :email => "john@example.com" } })
    
    # Compare expected hash and actual result parsed by JSON parser
    assert_equal({ "timestamp" => Time.now,
                   "person" => {
                     "id" => 13,
                     "name" => "John",
                     "email" => "john@example.com",
                     "created_at" => Time.now,
                     "updated_at" => Time.now
                   }
                 }, JSON.parse(@response.body))
  
You may point out some problems on the test.

* The ID of the result may be different from 13
* It is not sure to assume `result["timestamp"]` is equal to `Time.now`
* It is not sure to assume `result["person"]["created_at"]` is equal to `Time.now`

The root of the problems is that the comparison is too strict. The
properties I would like to test is only its `name` and `email`
fields. So I should test like the following:

    assert_equal "John", result["person"]["name"]
    assert_equal "john@example.com", result["person"]["email"]

It looks too complicated, and we need some way to compare structures.
This library, UnificationAssertion, provides the primitive for the
comparison called `assert_unifiable`.

    assert_unifiable({ "timestamp" => :_,
                       "person" => {
                         "id" => :_,
                         "name" => "John",
                         "email" => "john@example.com",
                         "created_at" => :_a,
                         "updated_at" => :_a
                       }
                     }, JSON.parse(@response.body))

Symbols `:_a` for example, where its name starts with `_` is
interpreted as a meta variable. `assert_unifiable` does not care their
exact value is, but only the existence (can be `nil`) and equalities
for each occurance will be tested. The special symbol `:_` is a
wildcard.  It can appear many times, but it will not be bound with any
value.

## Examples

    assert_unifiable(:_a, 1)              # pass, :_a will be 1
    assert_unifiable([:_a, 1], [1, 1])    # pass, :_a will be 1
    assert_unifiable([:_, :_], [1, 2])    # pass, :_ can not be bound with any value
    assert_unifiable([:_a, :_a], [1, 2])  # fail, :_a can not be either 1 and 2
    assert_unifiable([:_a], [1,2,3])      # fail, :_a can be a value but can not be a sequence
    
    assert_unifiable({ :x => :_a }, { :x => 1 })     # pass, :_a will be 1
    assert_unifiable({ :y => :_a }, { })             # fail, a key :y should be present
    assert_unifiable({ :y => :_a }, { :y => nil })   # pass, :_a will be nil
    assert_unifiable({ :_a => 1 }, { :x => 1 })      # fail, meta variable can not appear as a key
    
    # assert_unifiable can receive a block, which will be yielded with the result of unification.
    assert_unifiable([:_a, :_b], [1, 2]) do |unifier|
      assert unifier[:_a] < unifier[:_b]
    end

## Installation

Update your `Gemfile`.

    gem "unification_assertion", :git => "git@github.com:soutaro/unification_assertion"

Write your test case.

    require "minitest/autorun"
    require "unification_assertion"
    
    class GreatTest < MiniTest::Unit::TestCase
      include UnificationAssertion
      
      def test_something
        assert_unifiable([:_a, :_b], [1, 2])
      end
    end

## Known Issues

### It skips occur check

The recursive pattern can not be processed well.

    assert_unifiable(:_a, { :x => :_a })

Usual unification algorithm rejects such input by *occur check*.  This
library is expected to be used for testing, so that I omit the
checking. (Who in the world will write such comparison?)

## Author

Written by Soutaro Matsumoto. (matsumoto at soutaro dot com)

Released under the MIT License: www.opensource.org/licenses/mit-license.php

github.com/soutaro/unification_assertion
