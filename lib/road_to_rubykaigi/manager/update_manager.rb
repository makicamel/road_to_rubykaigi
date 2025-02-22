module RoadToRubykaigi
  module Manager
    class UpdateManager
      def update(offset_x:)
        @entities.each(&:update)
        enforce_boundary(offset_x: offset_x)
      end

      private

      def initialize(map, foreground)
        @map = map
        @entities = foreground.layers
      end

      def enforce_boundary(offset_x:)
        @entities.each do |entity|
          entity.respond_to?(:enforce_boundary) && entity.enforce_boundary(@map, offset_x:)
        end
      end
    end
  end
end
