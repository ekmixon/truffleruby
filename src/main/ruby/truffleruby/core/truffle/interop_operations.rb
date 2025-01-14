# frozen_string_literal: true

# Copyright (c) 2021, 2021 Oracle and/or its affiliates. All rights reserved. This
# code is released under a tri EPL/GPL/LGPL license. You can use it,
# redistribute it and/or modify it under the terms of the:
#
# Eclipse Public License version 2.0, or
# GNU General Public License version 2, or
# GNU Lesser General Public License version 2.1.

module Truffle
  module InteropOperations
    TO_ENUM = Kernel.instance_method(:to_enum)

    def self.get_iterator(obj)
      TO_ENUM.bind_call(obj, :each)
    end

    def self.enumerator_has_next?(enum)
      begin
        enum.peek
        true
      rescue StopIteration
        false
      end
    end

    RESOLVE_POLYGLOT_CLASS_MUTEX = Mutex.new

    def self.resolve_polyglot_class(*traits)
      return Polyglot::ForeignObject if traits.empty?
      name = "Foreign#{traits.join}"

      RESOLVE_POLYGLOT_CLASS_MUTEX.synchronize do
        if Polyglot.const_defined?(name, false)
          Polyglot.const_get(name, false)
        else
          foreign_class = Class.new(Polyglot::ForeignObject)
          traits.reverse_each do |trait|
            foreign_class.include Polyglot.const_get("#{trait}Trait", false)
          end
          Polyglot.const_set(name, foreign_class)
          foreign_class
        end
      end
    end

    def self.foreign_inspect_nonrecursive(object)
      object = Truffle::Interop.unbox_if_needed(object)

      hash_code = "0x#{Truffle::Interop.identity_hash_code(object).to_s(16)}"
      klass = ruby_class_and_language(object)

      if Truffle::Interop.java_class?(object)
        "#<#{klass} class #{object.class.getName}>"
      else
        string = +"#<#{klass}"
        if Truffle::Interop.has_meta_object?(object)
          meta_object = Truffle::Interop.meta_object(object)
          string << " #{Truffle::Interop.meta_qualified_name meta_object}"
        end

        if Truffle::Interop.pointer?(object)
          string << " 0x#{Truffle::Interop.as_pointer(object).to_s(16)}"
        else
          string << ":#{hash_code}"
        end

        array_or_map = false
        if Truffle::Interop.has_array_elements?(object)
          array_or_map = true
          string << " [#{object.map { |e| basic_inspect_for e }.join(', ')}]"
        end
        if Primitive.interop_java_map?(object)
          array_or_map = true
          string << " {#{pairs_from_java_map(object).map { |k, v| "#{basic_inspect_for k}=>#{basic_inspect_for v}" }.join(', ')}}"
        end
        if Truffle::Interop.has_members?(object) and !array_or_map
          pairs = pairs_from_object(object)
          unless pairs.empty?
            string << " #{pairs.map { |k, v| "#{k}=#{basic_inspect_for v}" }.join(', ')}"
          end
        end
        if Truffle::Interop.executable?(object)
          string << ' proc'
        end

        string << '>'
      end
    end

    def self.basic_inspect_for(object)
      if Truffle::Interop.string?(object)
        object.inspect
      elsif Truffle::Interop.has_array_elements?(object)
        '[...]'
      elsif (Truffle::Interop.java?(object) && Primitive.interop_java_map?(object)) || Truffle::Interop.has_members?(object)
        '{...}'
      else
        object.inspect
      end
    end

    def self.recursive_string_for(object)
      if Truffle::Interop.has_array_elements?(object)
        '[...]'
      elsif Truffle::Interop.java?(object) && Primitive.interop_java_map?(object) || Truffle::Interop.has_members?(object)
        '{...}'
      else
        # This last case should not currently be hit, but could be if we extend inspect with new cases.
        hash_code = "0x#{Truffle::Interop.identity_hash_code(object).to_s(16)}"
        Truffle::Interop.java?(object) ? "<Java:#{hash_code} ...>" : "<Foreign:#{hash_code} ...>"
      end
    end

    def self.pairs_from_java_map(map)
      map.entrySet.toArray.map do |key_value|
        [key_value.getKey, key_value.getValue]
      end
    end

    def self.pairs_from_object(object)
      readable_members = Truffle::Interop.members(object).select { |member| Truffle::Interop.member_readable?(object, member) }
      readable_members.map { |key| [key, object[key]] }
    end

    def self.ruby_class_and_language(object)
      klass = Truffle::Type.object_class(object)
      language = Truffle::Interop.language(object)
      language ? "#{klass}[#{language}]" : klass
    end
  end
end
