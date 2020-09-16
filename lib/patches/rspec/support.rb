# Copyright © 2013 David Chelimsky, Myron Marston, Jon Rowe, Sam Phippen,
# Xavier Shay, Bradley Schaefer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'rspec/support'

module RSpec
  module Support
    module RubyFeatures
      module_function
      def ripper_supported?
        true
      end
    end

    def self.define_optimized_require_for_rspec(lib, &require_relative)
      name = "require_rspec_#{lib}"

      (class << self; self; end).__send__(:define_method, name) do |f|
        require "rspec/#{lib}/#{f}"
      end
    end

    define_optimized_require_for_rspec(:support)
    define_optimized_require_for_rspec(:core)
  end
end
