namespace :tw do
  namespace :maintenance do
    namespace :cached do

      desc 'build CachedMapItems for Georeferences that do not have them'
      task parallel_create_cached_map_from_georeferences: [:environment] do |t|
        q = Georeference.where.missing(:cached_map_register)

        puts "Caching #{q.all.size} georeferences records."

        cached_rebuild_processes = ENV['cached_rebuild_processes'] ? ENV['cached_rebuild_processes'].to_i : 4

        Parallel.each(q.find_each, progress: 'build_cached_map_from_georeferences', in_processes: cached_rebuild_processes ) do |g|
          begin
            CachedMapItem.transaction do
              reconnected ||= Georeference.connection.reconnect! || true # https://github.com/grosser/parallel
              g.send(:create_cached_map_items)
            end
            true
          rescue => exception
            puts " FAILED #{exception} #{g.id}"
          end
          true
        end

        puts 'Done.'
      end

      desc 'build CachedMapItems for AssertedDistributions that do not have them'
      task parallel_create_cached_map_from_asserted_distributions: [:environment] do |t|
        q = AssertedDistribution.joins(:geographic_items).where.missing(:cached_map_register)

        puts "Caching #{q.all.size} AssertedDistribution records."

        cached_rebuild_processes = ENV['cached_rebuild_processes'] ? ENV['cached_rebuild_processes'].to_i : 4

        Parallel.each(q.find_each, progress: 'build_cached_map_from_asserted_distributions', in_processes: cached_rebuild_processes ) do |ad|
          begin
            CachedMapItem.transaction do
              reconnected ||= AssertedDistribution.connection.reconnect! || true # https://github.com/grosser/parallel
              ad.send(:create_cached_map_items)
            end
            true
          rescue => exception
            puts " FAILED #{exception} #{ad.id}"
          end
          true
        end

        puts'Done.'

      end

      desc 'forces rebuild of all GeographicItem cached fields'
      task parallel_reset_geographic_item_cached_ids: [:environment] do |t|

        cached_rebuild_processes = ENV['cached_rebuild_processes'] ? ENV['cached_rebuild_processes'].to_i : 16

        q = GeographicItem.all

        Parallel.each(q.find_each, progress: 'update_geographic_item_cached_fields', in_processes: cached_rebuild_processes ) do |gi|
            begin
              gi.set_cached
            rescue => exception
              puts Rainbow(" FAILED #{exception}").red.bold
            end
          end
      end

      desc 'forces rebuild of all GeographicItem cached fields'
      task parallel_reset_geographic_item_cached_ids: [:environment] do |t|

        q = GeographicItem.all

        Parallel.each(q.limit(100).find_each, progress: 'update_geographic_item_cached_fields', in_processes: cached_rebuild_processes ) do |gi|
            begin
              gi.set_cached
            rescue => exception
              puts Rainbow(" FAILED #{exception}").red.bold
            end
          end
      end

      # If force = 'true' then re-do records that already have cached set
      desc 'rake tw:maintenance:cached:parallel_rebuild_cached_author force=true cached_rebuild_processes=4'
      task parallel_rebuild_cached_author: [:environment] do |t|

        a = TaxonName.where.not(verbatim_author: nil)
        b = TaxonName.joins(:taxon_name_authors) # TODO: should be Protonym + what Plant/other names?

        query = TaxonName.from("((#{a.to_sql}) UNION (#{b.to_sql})) as taxon_names")

        if ENV['force'] != 'true'
          query = query.where(cached_author: nil)
        end

        puts Rainbow("Processing #{query.count} records").purple

        cached_rebuild_processes = ENV['cached_rebuild_processes'] ? ENV['cached_rebuild_processes'].to_i : 16

        #  !! Parallel *does not* like query.find_each !!
        Parallel.each(query.each, progress: 'update_cached_author', in_processes: cached_rebuild_processes ) do |n|
          begin
            n.set_cached_author
          rescue => exception
            puts Rainbow(" FAILED #{exception}").red.bold
          end
          true
        end
      end

      # This task does not touch Housekeeping!
      desc 'rake tw:maintenance:cached:parallel_rebuild_cached_original_combinations project_id=1 cached_rebuild_processes=16'
      task parallel_rebuild_cached_original_combinations: [:environment, :project_id] do |t|
        GC.start # VERY important, line below will fork into [number of threads] copies of this process, so memory usage must be as minimal as possible before starting.
        # Runs in parallel only if PARALLEL_PROCESSOR_COUNT is explicitely set
        #
        query = Protonym.is_species_or_genus_group
          .joins(:original_combination_relationships)
          .where(
            project_id: @args[:project_id],
            cached_original_combination: nil)

        puts Rainbow("Processing #{query.count} records").purple

        cached_rebuild_processes = ENV['cached_rebuild_processes'] ? ENV['cached_rebuild_processes'].to_i : 16

        Parallel.each(query.find_each, progress: 'update_cached_original_combinations', in_processes: cached_rebuild_processes ) do |n|
          begin
            n.update_cached_original_combinations
          rescue => exception
            puts Rainbow(" FAILED #{exception}").red.bold
            puts Rainbow(" FAILED #{exception}").red.bold
          end
          true
        end
      end

      # This task does not touch Housekeeping!
      desc 'rake tw:maintenance:cached:rebuild_cached_original_combinations project_id=1'
      task  rebuild_cached_original_combinations: [:environment, :project_id] do |t|
        query = Protonym.is_species_or_genus_group
          .joins(:original_combination_relationships)
          .where(
            project_id: Current.project_id,
            cached_original_combination: nil)

        puts Rainbow("Processing #{query.count} records").purple

        query.find_each do |p|
          print Rainbow( p.name + ' [' + p.id.to_s + ']' ).yellow
          begin
            p.update_cached_original_combinations
            puts Rainbow(' PROCESSED OK').green.bold
          rescue => e
            puts Rainbow(" FAILED #{e}").red.bold
          end
          true
        end
      end
    end

  end
end

