require 'journey/gtg/transition_table'

module Journey
  module GTG
    class Builder
      DUMMY = Nodes::Literal.new Object.new # :nodoc:

      attr_reader :root, :ast, :endpoints

      def initialize root
        @root         = root
        @ast          = Nodes::Cat.new root, DUMMY
        @followpos    = nil
      end

      def transition_table
        dtrans   = TransitionTable.new
        marked   = {}
        state_id = Hash.new { |h,k| h[k] = h.length }

        start   = firstpos(root)
        dstates = [start]
        until dstates.empty?
          s = dstates.shift
          next if marked[s]
          marked[s] = true # mark s

          s.group_by { |state| symbol(state) }.each do |sym, ps|
            u = ps.map { |l| followpos(l) }.flatten
            next if u.empty?

            if u == [DUMMY]
              #dtrans[state_id[s], state_id[Object.new]] = sym
              dtrans[state_id[s], state_id[u]] = sym
            else
              dtrans[state_id[s], state_id[u]] = sym

              #if u.include? DUMMY
              #  p sym => state_id[u]
              #end
            end

            dstates << u
          end
        end

        dtrans
      end

      def nullable? node
        case node
        when Nodes::Group
          true
        when Nodes::Star
          true
        when Nodes::Or
          nullable?(node.left) || nullable?(node.right)
        when Nodes::Cat
          nullable?(node.left) && nullable?(node.right)
        when Nodes::Terminal
          !node.left
        when Nodes::Unary
          nullable? node.left
        else
          raise ArgumentError, 'unknown nullable: %s' % node.class.name
        end
      end

      def firstpos node
        case node
        when Nodes::Star
          firstpos(node.left)
        when Nodes::Cat
          if nullable? node.left
            firstpos(node.left) | firstpos(node.right)
          else
            firstpos(node.left)
          end
        when Nodes::Or
          firstpos(node.left) | firstpos(node.right)
        when Nodes::Unary
          firstpos(node.left)
        when Nodes::Terminal
          nullable?(node) ? [] : [node]
        else
          raise ArgumentError, 'unknown firstpos: %s' % node.class.name
        end
      end

      def lastpos node
        case node
        when Nodes::Star
          firstpos(node.left)
        when Nodes::Or
          lastpos(node.right) | lastpos(node.left)
        when Nodes::Cat
          if nullable? node.right
            lastpos(node.left) | lastpos(node.right)
          else
            lastpos(node.right)
          end
        when Nodes::Terminal
          nullable?(node) ? [] : [node]
        when Nodes::Unary
          lastpos(node.left)
        else
          raise ArgumentError, 'unknown lastpos: %s' % node.class.name
        end
      end

      def followpos node
        followpos_table[node]
      end

      private
      def followpos_table
        @followpos ||= build_followpos
      end

      def build_followpos
        table = Hash.new { |h,k| h[k] = [] }
        @ast.each do |n|
          case n
          when Nodes::Cat
            lastpos(n.left).each do |i|
              table[i] += firstpos(n.right)
            end
          when Nodes::Star
            lastpos(n).each do |i|
              table[i] += firstpos(n)
            end
          end
        end
        table
      end

      def symbol edge
        case edge
        when Journey::Nodes::Symbol
          edge.regexp
        else
          edge.left
        end
      end
    end
  end
end