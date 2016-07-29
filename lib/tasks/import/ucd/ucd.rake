require 'fileutils'

### rake tw:project_import:ucd:import_ucd data_directory=/Users/proceps/src/sf/import/ucd/working/ no_transaction=true



# COLL.txt         Done
# COUNTRY.txt      Done
# DIST.txt
# FAMTRIB.txt       Done
# FGNAMES.txt       Done
# GENUS.txt         Done
# H-FAM.txt
# HKNEW.txt
# HOSTFAM.txt
# HOSTS.txt
# JOURNALS.txt
# KEYWORDS.txt
# LANGUAGE.txt     Done
# MASTER.txt       Done
# P-TYPE.txt
# REFEXT.txt
# RELATION.txt
# RELIABLE.txt
# SPECIES.txt     Done
# STATUS.txt
# TRAN.txt
# TSTAT.txt
# WWWIMAOK.txt

namespace :tw do
  namespace :project_import do
    namespace :ucd do


      class ImportedDataUcd
        attr_accessor :publications_index, :genera_index, :species_index, :keywords, :family_groups, :superfamilies, :families,
                      :taxon_codes, :languages, :references, :countries, :collections, :all_genera_index, :all_species_index, :topics
        def initialize()
          @publications_index = {}
          @keywords = {}
          @genera_index = {}
          @all_genera_index = {}
          @species_index = {}
          @all_species_index = {}
          @family_groups = {}
          @superfamilies = {}
          @families = {}
          @taxon_codes = {}
          @languages = {}
          @countries = {}
          @collections = {}
          @references = {}
          @topics = {}
        end


      end

      task :import_ucd => [:data_directory, :environment] do |t|


        if ENV['no_transaction']
          puts 'Importing without a transaction (data will be left in the database).'
          main_build_loop_ucd
        else

          ActiveRecord::Base.transaction do
            begin
              main_build_loop_ucd
            rescue
              raise
            end
          end

        end

      end

      def main_build_loop_ucd
        print "\nStart time: #{Time.now}\n"

        @import = Import.find_or_create_by(name: @import_name)
        @import.metadata ||= {}
        @data =  ImportedDataUcd.new
        puts @args
        Utilities::Files.lines_per_file(Dir["#{@args[:data_directory]}/**/*.txt"])

        handle_projects_and_users_ucd
        raise '$project_id or $user_id not set.'  if $project_id.nil? || $user_id.nil?

        $project_id = 1
        @root = Protonym.find_or_create_by(name: 'Root', rank_class: 'NomenclaturalRank', project_id: $project_id)

        handle_language_ucd
        handle_countries_ucd
        handle_collections_ucd

#        handle_references_ucd

#        handle_fgnames_ucd
#        handle_master_ucd_families
#        handle_master_ucd_valid_genera
#        handle_master_ucd_invalid_genera
#        handle_master_ucd_invalid_subgenera
#        handle_master_ucd_valid_species
#        handle_master_ucd_invalid_species
#        handle_family_ucd
#        handle_genus_ucd
        handle_species_ucd

#        handle_keywords_ucd
#        handle_hknew_ucd
#        handle_h_fam_ucd
#        handle_hostfam_ucd


        print "\n\n !! Success. End time: #{Time.now} \n\n"

      end

      def handle_projects_and_users_ucd
        print "\nHandling projects and users "
        email = 'eucharitid@mail.net'
        project_name = 'UCD'
        user_name = 'eucharitid'
        $user_id, $project_id = nil, nil
        if @import.metadata['project_and_users']
          print "from database.\n"
          project = Project.where(name: project_name).first
          user = User.where(email: email).first
          $project_id = project.id
          $user_id = user.id
        else
          print "as newly parsed.\n"

          user = User.where(email: email)
          if user.empty?
            user = User.create(email: email, password: '3242341aas', password_confirmation: '3242341aas', name: user_name, self_created: true)
          else
            user = user.first
          end
          $user_id = user.id # set for project line below

          project = nil

          if project.nil?
            project = Project.create(name: project_name)
          end

          $project_id = project.id
          pm = ProjectMember.new(user: user, project: project, is_project_administrator: true)
          pm.save! if pm.valid?

          @import.metadata['project_and_users'] = true
        end
        @root = Protonym.find_or_create_by(name: 'Root', rank_class: 'NomenclaturalRank', project_id: $project_id)
        @order = Protonym.find_or_create_by(name: 'Hymenoptera', parent: @root, rank_class: 'NomenclaturalRank::Iczn::HigherClassificationGroup::Order', project_id: $project_id)
        @data.superfamilies['1'] = Protonym.find_or_create_by(name: 'Serphitoidea', parent: @order, rank_class: 'NomenclaturalRank::Iczn::FamilyGroup::Superfamily', project_id: $project_id).id
        @data.superfamilies['2'] = Protonym.find_or_create_by(name: 'Chalcidoidea', parent: @order, rank_class: 'NomenclaturalRank::Iczn::FamilyGroup::Superfamily', project_id: $project_id).id
        @data.superfamilies['3'] = Protonym.find_or_create_by(name: 'Mymarommatoidea', parent: @order, rank_class: 'NomenclaturalRank::Iczn::FamilyGroup::Superfamily', project_id: $project_id).id
        @data.families[''] = @order.id
        @data.keywords['ucd_imported'] = Keyword.find_or_create_by(name: 'ucd_imported', definition: 'Imported from UCD database.')
        @data.keywords['taxon_id'] = Namespace.find_or_create_by(name: 'UCD_Taxon_ID', short_name: 'UCD_Taxon_ID')
        @data.keywords['family_id'] = Namespace.find_or_create_by(name: 'UCD_Family_ID', short_name: 'UCD_Family_ID')
        @data.keywords['host_family_id'] = Namespace.find_or_create_by(name: 'UCD_Host_Family_ID', short_name: 'UCD_Host_Family_ID')
      end

      def handle_fgnames_ucd
        #FamCode
        # FamGroup
        # Family
        # Subfam
        # Tribe
        # SuperfamFK
        # SortOrder
        path = @args[:data_directory] + 'FGNAMES.txt'
        print "\nHandling FGNAMES\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')
        file.each_with_index do |row, i|
          print "\r#{i}"
          family = row['Family'].blank? ? nil : Protonym.find_or_create_by!(name: row['Family'], parent_id: @data.superfamilies[row['SuperfamFK']], rank_class: 'NomenclaturalRank::Iczn::FamilyGroup::Family', project_id: $project_id)
          subfamily = row['Subfam'].blank? ? nil : Protonym.find_or_create_by!(name: row['Subfam'], parent: family, rank_class: 'NomenclaturalRank::Iczn::FamilyGroup::Subfamily', project_id: $project_id)
          tribe = row['Tribe'].blank? ? nil : Protonym.find_or_create_by!(name: row['Tribe'], parent: subfamily, rank_class: 'NomenclaturalRank::Iczn::FamilyGroup::Tribe', project_id: $project_id)

          if !tribe.nil?
            @data.families[row['FamCode']] = tribe.id
            tribe.identifiers.create!(type: 'Identifier::Local::Import', namespace: @data.keywords['family_id'], identifier: row['FamCode'].to_s)
          elsif !subfamily.nil?
            @data.families[row['FamCode']] = subfamily.id
            subfamily.identifiers.create!(type: 'Identifier::Local::Import', namespace: @data.keywords['family_id'], identifier: row['FamCode'].to_s)
          else
            @data.families[row['FamCode']] = family.id
            family.identifiers.create!(type: 'Identifier::Local::Import', namespace: @data.keywords['family_id'], identifier: row['FamCode'].to_s)
          end
        end
      end

      def handle_master_ucd_families
        #TaxonCode
        # ValGenus
        # ValSpecies
        # HomCode
        # ValAuthor
        # CitGenus
        # CitSubgen
        # CitSpecies
        # CitSubsp
        # CitAuthor
        # Family
        # ValDate
        # CitDate
        path = @args[:data_directory] + 'MASTER.txt'
        print "\nHandling MASTER -- Families\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')
        file.each_with_index do |row, i|
          print "\r#{i}"
          if row['ValGenus'].blank?
            name = row['ValAuthor'].split(' ').first
            author = row['ValAuthor'].gsub(name + ' ', '')
            taxon = Protonym.find_or_create_by(name: name, project_id: $project_id)
            taxon.parent = @order if taxon.parent_id.nil?
            taxon.year_of_publication = row['ValDate'] if taxon.year_of_publication.nil?
            taxon.verbatim_author = author if taxon.verbatim_author.nil?
            taxon.rank_class = 'NomenclaturalRank::Iczn::FamilyGroup::Superfamily' if taxon.rank_class.nil? && name.include?('oidea')
            taxon.rank_class = 'NomenclaturalRank::Iczn::FamilyGroup::Family' if taxon.rank_class.nil? && name.include?('idae')
            taxon.rank_class = 'NomenclaturalRank::Iczn::FamilyGroup::Subfamily' if taxon.rank_class.nil? && name.include?('inae')
            byebug unless taxon.valid?
            taxon.save!

            if row['ValAuthor'] == row['CitAuthor']
              @data.taxon_codes[row['TaxonCode']] = taxon.id
              taxon.identifiers.create!(type: 'Identifier::Local::Import', namespace: @data.keywords['taxon_id'], identifier: row['TaxonCode'].to_s)
            else
              name = row['CitAuthor'].split(' ').first
              author = row['CitAuthor'].gsub(name + ' ', '')
              rank = taxon.rank_class
              vname = nil
              if rank.parent.to_s == 'NomenclaturalRank::Iczn::FamilyGroup'
                alternative_name = Protonym.family_group_name_at_rank(name, rank.rank_name)
                if name != alternative_name
                  name = alternative_name
                  vname = row['Name']
                end
              end

              taxon1 = Protonym.new(
                       name: name,
                       verbatim_name: vname,
                       parent: taxon.parent,
                       rank_class: taxon.rank_class,
                       verbatim_author: author,
                       year_of_publication: row['CitDate']
              )
              if taxon1.valid?
                taxon1.save!
              elsif !taxon1.errors.messages[:name].blank?
                taxon1.taxon_name_classifications.new(type: 'TaxonNameClassification::Iczn::Unavailable::NotLatin')
                taxon1.save!
              else
                byebug
              end
              @data.taxon_codes[row['TaxonCode']] = taxon1.id
              taxon1.identifiers.create!(type: 'Identifier::Local::Import', namespace: @data.keywords['taxon_id'], identifier: row['TaxonCode'].to_s)
              taxon1.data_attributes.create!(type: 'ImportAttribute', import_predicate: 'HomCode', value: row['HomCode']) unless row['HomCode'].blank?
              TaxonNameRelationship.create!(subject_taxon_name: taxon1, object_taxon_name: taxon, type: 'TaxonNameRelationship::Iczn::Invalidating::Synonym')
            end
          end
        end
      end

      def handle_master_ucd_valid_genera
        path = @args[:data_directory] + 'MASTER.txt'
        print "\nHandling MASTER -- Valid genera\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')
        file.each_with_index do |row, i|
          print "\r#{i}"
          if !row['ValGenus'].blank? && @data.genera_index[row['ValGenus']].nil?
            name = row['ValGenus']
            taxon = Protonym.find_or_create_by(name: name, project_id: $project_id)
            taxon.parent_id = find_family_id_ucd(row['Family']) if taxon.parent_id.nil?
            taxon.year_of_publication = row['ValDate'] if taxon.year_of_publication.nil? && row['ValSpecies'].blank?
            taxon.verbatim_author = row['ValAuthor'] if taxon.verbatim_author.nil? && row['ValSpecies'].blank?
            taxon.rank_class = 'NomenclaturalRank::Iczn::GenusGroup::Genus' if taxon.rank_class.nil?
            byebug unless taxon.valid?
            taxon.save!
            @data.all_genera_index[name] = taxon.id

            if row['ValGenus'].to_s == row['CitGenus'] && row['CitSubgen'].blank? && row['ValSpecies'].blank?  && row['CitSpecies'].blank?
              @data.genera_index[name] = taxon.id
              @data.taxon_codes[row['TaxonCode']] = taxon.id
              taxon.identifiers.create!(type: 'Identifier::Local::Import', namespace: @data.keywords['taxon_id'], identifier: row['TaxonCode'])
            end
          end
        end
      end

      def handle_master_ucd_invalid_genera
        path = @args[:data_directory] + 'MASTER.txt'
        print "\nHandling MASTER -- Invalid genera\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')
        file.each_with_index do |row, i|
          print "\r#{i}"
          if !row['CitGenus'].blank? && @data.taxon_codes[row['TaxonCode']].nil?
              taxon = Protonym.find_or_create_by(name: row['CitGenus'], project_id: $project_id)
              taxon1 = Protonym.find_by(name: row['ValGenus'], project_id: $project_id)
              taxon.parent_id = find_family_id_ucd(row['Family']) if taxon.parent_id.nil?
              taxon.year_of_publication = row['CitDate'] if taxon.year_of_publication.nil? && row['CitSpecies'].blank? && row['CitSubgenus'].blank?
              taxon.verbatim_author = row['CitAuthor'] if taxon.verbatim_author.nil? && row['CitSpecies'].blank? && row['CitSubgenus'].blank?
              taxon.rank_class = 'NomenclaturalRank::Iczn::GenusGroup::Genus' if taxon.rank_class.nil?
              if taxon.valid?
                taxon.save!
              else
                taxon.taxon_name_classifications.new(type: 'TaxonNameClassification::Iczn::Unavailable::NotLatin') if !taxon.errors.messages[:name].blank?
                taxon.save!
              end
              @data.all_genera_index[taxon.name] = taxon.id

              if row['ValSpecies'].blank? && row['CitSpecies'].blank? && row['CitSubgen'].blank?
                taxon.identifiers.create!(type: 'Identifier::Local::Import', namespace: @data.keywords['taxon_id'], identifier: row['TaxonCode'])
                if @data.genera_index[row['CitGenus']].nil?
                  @data.genera_index[taxon.name] = taxon.id
                  @data.taxon_codes[row['TaxonCode']] = taxon.id
                  TaxonNameRelationship.create!(subject_taxon_name: taxon, object_taxon_name: taxon1, type: 'TaxonNameRelationship::Iczn::Invalidating')
                end
              end
          end
        end
      end

      def handle_master_ucd_invalid_subgenera
        path = @args[:data_directory] + 'MASTER.txt'
        print "\nHandling MASTER -- Invalid subgenera\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')
        file.each_with_index do |row, i|
          print "\r#{i}"
          if !row['CitSubgen'].blank? && row['CitSpecies'].blank? && @data.taxon_codes[row['TaxonCode']].nil?
            name = row['CitSubgen'].gsub(')', '').gsub('?', '').capitalize
            parent = @data.genera_index[row['ValGenus']]
            taxon = Protonym.find_or_create_by(name: name, project_id: $project_id)
            taxon.parent_id = parent if taxon.parent_id.nil?
            taxon.year_of_publication = row['CitDate'] if taxon.year_of_publication.nil? && row['CitSpecies'].blank?
            taxon.verbatim_author = row['CitAuthor'] if taxon.verbatim_author.nil? && row['CitSpecies'].blank?
            taxon.rank_class = 'NomenclaturalRank::Iczn::GenusGroup::Subgenus' if taxon.rank_class.nil? && row['CitSpecies'].blank?
            byebug unless taxon.valid?
            taxon.save!
            @data.all_genera_index[name] = taxon.id

            if taxon.rank_class == 'NomenclaturalRank::Iczn::GenusGroup::Genus' && taxon.name == name
              origgen = @data.all_genera_index[row['CitGenus']]
              c = Combination.new()
              c.genus = TaxonName.find(origgen) unless origgen.nil?
              c.subgenus = taxon
              c.save!
            end
            @data.genera_index[name] = taxon.id
            @data.taxon_codes[row['TaxonCode']] = taxon.id
            taxon.identifiers.create!(type: 'Identifier::Local::Import', namespace: @data.keywords['taxon_id'], identifier: row['TaxonCode'])
          end
        end
      end

      def handle_master_ucd_valid_species
        path = @args[:data_directory] + 'MASTER.txt'
        print "\nHandling MASTER -- Valid species\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')
        file.each_with_index do |row, i|
          print "\r#{i}"
          if !@data.species_index[row['ValGenus'].to_s + ' ' + row['ValSpecies'].to_s].nil?
          elsif !row['ValSpecies'].blank? && @data.taxon_codes[row['TaxonCode']].nil?
            parent = @data.all_genera_index[row['ValGenus']]
            name = row['ValSpecies'].to_s
            taxon = Protonym.find_or_create_by(name: name, parent_id: parent, project_id: $project_id)
            taxon.year_of_publication = row['ValDate'] if taxon.year_of_publication.nil?
            taxon.verbatim_author = row['ValAuthor'] if taxon.verbatim_author.nil?
            taxon.rank_class = 'NomenclaturalRank::Iczn::SpeciesGroup::Species'
            if taxon.valid?
              taxon.save!
            else
              taxon.taxon_name_classifications.new(type: 'TaxonNameClassification::Iczn::Unavailable::NotLatin') if !taxon.errors.messages[:name].blank?
              taxon.save!
            end

            @data.all_species_index[row['ValGenus'].to_s + ' ' + name] = taxon.id
            if row['ValSpecies'].to_s == row['CitSpecies'] && row['ValAuthor'] == '(' + row['CitAuthor'] + ')' && row['ValDate'] == row['CitDate']
              @data.species_index[row['ValGenus'].to_s + ' ' + name] = taxon.id
              @data.taxon_codes[row['TaxonCode']] = taxon.id
              taxon.identifiers.create!(type: 'Identifier::Local::Import', namespace: @data.keywords['taxon_id'], identifier: row['TaxonCode'])
              origsubgen = @data.all_genera_index[row['CitSubgen']]
              TaxonNameRelationship.create!(subject_taxon_name: taxon, object_taxon_name: taxon, type: 'TaxonNameRelationship::OriginalCombination::OriginalSpecies')
              TaxonNameRelationship.create!(subject_taxon_name_id: parent, object_taxon_name: taxon, type: 'TaxonNameRelationship::OriginalCombination::OriginalGenus') if taxon.original_genus.nil?
              TaxonNameRelationship.create!(subject_taxon_name_id: origsubgen, object_taxon_name: taxon, type: 'TaxonNameRelationship::OriginalCombination::OriginalSubgenus') if taxon.original_subgenus.nil? && !origsubgen.nil?
            end
          end
        end
      end

      def handle_master_ucd_invalid_species
        path = @args[:data_directory] + 'MASTER.txt'
        print "\nHandling MASTER -- Invalid species\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')
        file.each_with_index do |row, i|
          print "\r#{i}"
          if !row['CitSpecies'].blank? && @data.taxon_codes[row['TaxonCode']].nil?
            parent = @data.all_genera_index[row['ValGenus']]
            origgen = @data.all_genera_index[row['CitGenus']]
            origsubgen = @data.all_genera_index[row['CitSubgen']]
            name = row['CitSpecies'].gsub('sp. ', '').to_s
            taxon = Protonym.find_or_create_by(name: name, parent_id: parent, project_id: $project_id)
            taxon.year_of_publication = row['CitDate'] if taxon.year_of_publication.nil?
            taxon.verbatim_author = row['CitAuthor'] if taxon.verbatim_author.nil?
            taxon.rank_class = 'NomenclaturalRank::Iczn::SpeciesGroup::Species'
            if taxon.valid?
              taxon.save!
            else
              taxon.taxon_name_classifications.new(type: 'TaxonNameClassification::Iczn::Unavailable::NotLatin') if !taxon.errors.messages[:name].blank?
              taxon.save!
            end

            @data.taxon_codes[row['TaxonCode']] = taxon.id
            #@data.species_index[row['ValGenus'].to_s + ' ' + name] = taxon.id
            taxon1 = @data.all_species_index[row['ValGenus'].to_s + ' ' + row['ValSpecies'].to_s]
            byebug if taxon1.nil?
            if taxon.id == taxon1 || !taxon.original_genus.nil?
                c = Combination.new()
                c.genus = TaxonName.find(origgen) unless origgen.nil?
                c.subgenus = TaxonName.find(origsubgen) unless origsubgen.nil?
                c.species = taxon
                c.save!
            else
              TaxonNameRelationship.create!(subject_taxon_name: taxon, object_taxon_name_id: taxon1, type: 'TaxonNameRelationship::Iczn::Invalidating')
              TaxonNameRelationship.create!(subject_taxon_name_id: origgen, object_taxon_name: taxon, type: 'TaxonNameRelationship::OriginalCombination::OriginalGenus') if taxon.original_genus.nil?
              TaxonNameRelationship.create!(subject_taxon_name_id: origsubgen, object_taxon_name: taxon, type: 'TaxonNameRelationship::OriginalCombination::OriginalSubgenus') if taxon.original_subgenus.nil? && !origsubgen.nil?
            end
            taxon.identifiers.create!(type: 'Identifier::Local::Import', namespace: @data.keywords['taxon_id'], identifier: row['TaxonCode'])
          end
        end
      end

      def handle_language_ucd

        lng_transl = {'al' => 'sq',
                      'ge' => 'ka',
                      'gr' => 'el',
                      'in' => 'id',
                      'kz' => 'kk',
                      'ma' => 'mk',
                      'pe' => 'fa',
                      'sh' => 'hr',
                      'vt' => 'vi'
        }
        path = @args[:data_directory] + 'LANGUAGE.txt'
        print "\nHandling LANGUAGE\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')
        file.each_with_index do |row, i|
          print "\r#{i}"
          c = row['Code'].downcase
          c = lng_transl[c] unless lng_transl[c].nil?
          l = Language.where(alpha_2: c).first
          if l.nil?
            print "\n   Language not resolved: #{row['Code']} - #{row['Language']}\n"
            @data.languages[row['Code'].downcase] = [nil, row['Language']]
          else
            @data.languages[row['Code'].downcase] = [l.id, row['Language']]
          end
        end
      end

      def handle_countries_ucd
        path = @args[:data_directory] + 'COUNTRY.txt'
        print "\nHandling COUNTRY\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')
        file.each_with_index do |row, i|
          print "\r#{i}"
          @data.countries[row['Country'] + '|' + row['State']] = row['UCD_name']
        end
      end

      def handle_collections_ucd
        path = @args[:data_directory] + 'COLL.txt'
        print "\nHandling COLL\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')
        file.each_with_index do |row, i|
          print "\r#{i}"
          @data.collections[row['Acronym']] = row['Depository']
        end
      end

      def handle_references_ucd
          # - 0   RefCode   | varchar(15)  |
          # - 1   Author    | varchar(52)  |
          # - 2   Year      | varchar(4)   |
          # - 3   Letter    | varchar(2)   | # ?! key/value - if they want to maintain a manual system let them
          # - 4   PubDate   | date         |
          # - 5   Title     | varchar(188) |
          # - 6   JourBook  | varchar(110) |
          # - 7   Volume    | varchar(20)  |
          # - 8   Pages     | varchar(36)  |
          # - 9   Location  | varchar(27)  | # Attribute::Internal
          # - 10  Source    | varchar(28)  | # Attribute::Internal
          # - 11  Check     | varchar(11)  | # Attribute::Internal
          # - 12  ChalcFam  | varchar(20)  | # Attribute::Internal a key/value (memory aid of john)
          # - 13  KeywordA  | varchar(2)   | # Tag
          # - 14  KeywordB  | varchar(2)   | # Tag
          # - 15  KeywordC  | varchar(2)   | # Tag
          # - 16  LanguageA | varchar(2)   | Attribute::Internal & Language
          # - 17  LanguageB | varchar(2)   | Attribute::Internal
          # - 18  LanguageC | varchar(2)   | Attribute::Internal
          # - 19  M_Y       | varchar(1)   | # Attribute::Internal fuzziness on month/day/year - an annotation
          # 20  PDF_file  | varchar(1)   | # [X or Y] TODO: NOT HANDLED

          # 0 RefCode
          # - 1 Translate
          # - 2 Notes
          # - 3 Publisher
          # - 4 ExtAuthor
          # - 5 ExtTitle
          # - 6 ExtJournal
          # - 7 Editor

        path1 = @args[:data_directory] + 'REFS.txt'
        path2 = @args[:data_directory] + 'REFEXT.txt'
        print "\nHandling References\n"
        raise "file #{path1} not found" if not File.exists?(path1)
        raise "file #{path2} not found" if not File.exists?(path2)
        file1 = CSV.foreach(path1, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')
        file2 = CSV.foreach(path2, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')

        namespace = Namespace.find_or_create_by(name: 'UCD_RefCode', short_name: 'UCD_RefCode')
        keywords = {
            'Refs:Location' => Predicate.find_or_create_by(name: 'Refs::Location', definition: 'The verbatim value in Ref#location.', project_id: $project_id),
            'Refs:Source' => Predicate.find_or_create_by(name: 'Refs::Source', definition: 'The verbatim value in Ref#source.', project_id: $project_id),
            'Refs:Check' => Predicate.find_or_create_by(name: 'Refs::Check', definition: 'The verbatim value in Ref#check.', project_id: $project_id),
            'Refs:LanguageA' => Predicate.find_or_create_by(name: 'Refs::LanguageA', definition: 'The verbatim value in Refs#LanguageA', project_id: $project_id),
            'Refs:LanguageB' => Predicate.find_or_create_by(name: 'Refs::LanguageB', definition: 'The verbatim value in Refs#LanguageB', project_id: $project_id),
            'Refs:LanguageC' => Predicate.find_or_create_by(name: 'Refs::LanguageC', definition: 'The verbatim value in Refs#LanguageC', project_id: $project_id),
            'Refs:ChalcFam' => Predicate.find_or_create_by(name: 'Refs::ChalcFam', definition: 'The verbatim value in Refs#ChalcFam', project_id: $project_id),
            'Refs:M_Y' => Predicate.find_or_create_by(name: 'Refs::M_Y', definition: 'The verbatim value in Refs#M_Y.', project_id: $project_id),
            'Refs:PDF_file' => Predicate.find_or_create_by(name: 'Refs::PDF_file', definition: 'The verbatim value in Refs#PDF_file.', project_id: $project_id),
            'RefsExt:Translate' => Predicate.find_or_create_by(name: 'RefsExt::Translate', definition: 'The verbatim value in RefsExt#Translate.', project_id: $project_id),
        }

        fext_data = {}
        file1.each_with_index do |r, i|
          fext_data.merge!(
              r[0] => { translate: r[1], notes: r[2], publisher: r[3], ext_author: r[4], ext_title: r[5], ext_journal: r[6], editor: r[7] }
          )
        end


        file1.each_with_index do |row, i|
          print "\r#{i}"

          year, month, day = nil, nil, nil
          unless row['PubDate'].nil?
            year, month, day = row['PubDate'].split('-', 3)
            month = Utilities::Dates::SHORT_MONTH_FILTER[month]
            month = month.to_s if !month.nil?
          end
          stated_year = row['Year']
          if year.nil?
            year = stated_year
            stated_year = nil
          end
          print "\nYear out of range: #{year}\n" if year.to_i < 1500 || year.to_i > 2018
          year = nil if year.to_i < 1500 || year.to_i > 2018
          stated_year = nil if stated_year.to_i < 1500 || stated_year.to_i > 2018

          title = [row['Title'],  (fext_data[row['RefCode']] && !fext_data[row['RefCode']][:ext_title].blank? ? fext_data[row['RefCode']][:ext_title] : nil)].compact.join(" ")
          journal = [row['JourBook'],  (fext_data[row['RefCode']] && !fext_data[row['RefCode']][:ext_journal].blank? ? fext_data[row['RefCode']][:ext_journal] : nil)].compact.join(" ")
          author = [row['Author'],  (fext_data[row['RefCode']] && !fext_data[row['RefCode']][:ext_author].blank? ? fext_data[row['RefCode']][:ext_author] : nil)].compact.join(" ")
          if row['LanguageA'].blank? || @data.languages[row['LanguageA'].downcase].nil?
            language, language_id = nil, nil
          else
            language_id = @data.languages[row['LanguageA'].downcase][0]
            language = @data.languages[row['LanguageA'].downcase][1]
          end
          serial_id = Serial.where(name: journal).limit(1).pluck(:id).first
          serial_id ||= Serial.with_any_value_for(:name, journal).limit(1).pluck(:id).first


          b = Source::Bibtex.new(
              author: author,
              year: (year.blank? ? nil : year.to_i),
              month: month,
              day: (day.blank? ? nil : day.to_i) ,
              stated_year: stated_year,
              year_suffix: row['Letter'],
              title: title,
              booktitle: journal,
              serial_id: serial_id,
              volume: row['Volume'],
              pages: row['Pages'],
              bibtex_type: 'article',
              language_id: language_id,
              language: language,
              publisher: (fext_data[row['RefCode']] ? fext_data[row['RefCode']][:publisher] : nil),
              editor: (fext_data[row['RefCode']] ? fext_data[row['RefCode']][:editor] : nil )
          )
          if b.valid?
            b.save
            b.identifiers.create!(type: 'Identifier::Local::Import', namespace: namespace, identifier: row['RefCode'])

            b.data_attributes.create!(type: 'InternalAttribute', predicate: keywords['Refs:Location'], value: row['Location'])   if !row['Location'].blank?
            b.data_attributes.create!(type: 'InternalAttribute', predicate: keywords['Refs:Source'], value: row['Source'])       if !row['Source'].blank?
            b.data_attributes.create!(type: 'InternalAttribute', predicate: keywords['Refs:Check'], value: row['Check'])         if !row['Check'].blank?
            b.data_attributes.create!(type: 'InternalAttribute', predicate: keywords['Refs:ChalcFam'], value: row['ChalcFam'])   if !row['ChalcFam'].blank?
            b.data_attributes.create!(type: 'InternalAttribute', predicate: keywords['Refs:LanguageA'], value: row['LanguageA']) if !row['LanguageA'].blank?
            b.data_attributes.create!(type: 'InternalAttribute', predicate: keywords['Refs:LanguageB'], value: row['LanguageB']) if !row['LanguageB'].blank?
            b.data_attributes.create!(type: 'InternalAttribute', predicate: keywords['Refs:LanguageC'], value: row['LanguageC']) if !row['LanguageC'].blank?
            b.data_attributes.create!(type: 'InternalAttribute', predicate: keywords['Refs:M_Y'], value: row['M_Y'])             if !row['M_Y'].blank?

            if fext_data[row['RefCode']]
              b.data_attributes.create!(type: 'InternalAttribute', predicate: keywords['RefsExt:Translate'], value: fext_data[row['RefCode']][:translate]) unless fext_data[row['RefCode']][:translate].blank?
              b.notes.create!(text: fext_data[row['RefCode']][:note]) unless fext_data[row['RefCode']][:note].blank?
            end

            ['KeywordA', 'KeywordB', 'KeywordC'].each do |i|
              k =  Keyword.with_alternate_value_on(:name, row[i]).first
              b.tags.build(keyword: k) unless k.nil?
            end
            @data.references[row['RefCode']] = b.id
          else
            #byebug
          end

        end
      end


      def handle_family_ucd
        path = @args[:data_directory] + 'FAMTRIB.txt'
        print "\nHandling FAMTRIB\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')

        keywords = {
            'FamTrib:Status' => Predicate.find_or_create_by(name: 'FamTrib:Status', definition: 'The verbatim value in FamTrib#Status.', project_id: $project_id)
        }.freeze

        status_type = {
            'FY' => 'Family of',
            'SB' => 'Subfamily of',
            'SF' => 'New status, subgenus of',
            'VF' => 'Family of',
            'VI' => 'Valid subtribe of',
            'VT' => 'Valid tribe of'
        }

        file.each_with_index do |row, i|
          print "\r#{i}"
          taxon = find_taxon_ucd(row['TaxonCode'])
          genus = find_taxon_id_ucd(row['Code'])
          ref = find_source_id_ucd(row['RefCode'])
          print "\n TaxonCode: #{row['TaxonCode']} not found \n" if !row['TaxonCode'].blank? || taxon.nil?
          print "\n Genus Code: #{row['Code']} not found \n" if !row['Code'].blank? || genus.nil?
          unless taxon.nil?
            unless genus.nil?
              TaxonNameRelationship.create!(type: 'TaxonNameRelationship::Typification::Family', subject_taxon_name_id: genus, object_taxon_name: taxon)
            end
            unless ref.nil?
              taxon.citations.create!(source_id: ref, pages: row['PageRef'], is_original: true)
            end
            taxon.notes.create!(text: row['Notes']) unless row['Notes'].blank?
            taxon.data_attributes.create!(type: 'InternalAttribute', predicate: keywords['FamTrib:Status'], value: status_type[row['Status']]) unless row['Status'].blank?
          end
          #byebug if i < 50
        end
      end


      def handle_genus_ucd
        path = @args[:data_directory] + 'GENUS.txt'
        print "\nHandling GENUS\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')

        type_type = {
            'MT' => 'TaxonNameRelationship::Typification::Genus::Monotypy::Original',
            'OD' => 'TaxonNameRelationship::Typification::Genus::OriginalDesignation',
            'OM' => 'TaxonNameRelationship::Typification::Genus::OriginalDesignation',
            'SD' => 'TaxonNameRelationship::Typification::Genus::SubsequentDesignation',
            'SM' => 'TaxonNameRelationship::Typification::Genus::Monotypy::Subsequent',
            ''   => 'TaxonNameRelationship::Typification::Genus'
        }.freeze

        keywords = {
            'Genus:Status' => Predicate.find_or_create_by(name: 'Genus:Status', definition: 'The verbatim value in Genus#Status.', project_id: $project_id)
        }.freeze

            status_type = {
            'NG' => 'New genus', # nothing
            'RN' => 'Replacement name', # relationship
            'SG' => 'Subgenus', # rank and parent
            'UE' => 'Unjustified emendantion', #relationship
            'UR' => 'Unnecessary replacement name', #relationship
            'US' => 'Unjustified emendation, new status' #relationship
        }

        file.each_with_index do |row, i|
          print "\r#{i}"
          taxon = find_taxon_ucd(row['TaxonCode'])
          species = find_taxon_id_ucd(row['Code'])
          ref = find_source_id_ucd(row['RefCode'])
          designator = find_source_id_ucd(row['Designator'])
          print "\n TaxonCode: #{row['TaxonCode']} not found \n" if !row['TaxonCode'].blank? || taxon.nil?
          print "\n Species Code: #{row['Code']} not found \n" if !row['Code'].blank? || species.nil?
          typedesign = row['TypeDesign'].blank? ? type_type[''] : type_type[row['TypeDesign']]
          unless taxon.nil?
            unless species.nil?
              TaxonNameRelationship.create(type: typedesign, subject_taxon_name_id: species, object_taxon_name: taxon,
                                            origin_citation_attributes: {source_id: designator, pages: row['PageDesign']})
            end
            unless ref.nil?
              taxon.citations.create(source_id: ref, pages: row['PageRef'], is_original: true)
            end
            taxon.notes.create(text: row['Notes']) unless row['Notes'].blank?
            taxon.data_attributes.create(type: 'InternalAttribute', predicate: keywords['Genus:Status'], value: status_type[row['Status']]) unless row['Status'].blank?
          end
          #byebug if i < 50
        end
      end

      def handle_species_ucd
        path = @args[:data_directory] + 'SPECIES.txt'
        print "\nHandling SPECIES\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')

        keywords = {
            'Region' => Predicate.find_or_create_by(name: 'Species:Region', definition: 'The verbatim value in Species#Region.', project_id: $project_id),
            'Species:Country' => Predicate.find_or_create_by(name: 'Species:Region', definition: 'The verbatim value in Species#Coutry-State.', project_id: $project_id),
            'Coll:Depository' => Predicate.find_or_create_by(name: 'Coll:Depository', definition: 'The verbatim value in Coll#Depository.', project_id: $project_id),
            'Sex' => Predicate.find_or_create_by(name: 'Species:Sex', definition: 'The verbatim value in Species#Sex.', project_id: $project_id),
            'Figures' => Predicate.find_or_create_by(name: 'Species:Figures', definition: 'The verbatim value in Species#Figures.', project_id: $project_id),
            'PrimType' => Predicate.find_or_create_by(name: 'Species:PrimType', definition: 'The verbatim value in Species#PrimType.', project_id: $project_id),
            'TypeSex' => Predicate.find_or_create_by(name: 'Species:TypeSex', definition: 'The verbatim value in Species#TypeSex.', project_id: $project_id),
            'Designator' => Predicate.find_or_create_by(name: 'Species:Designator', definition: 'The verbatim value in Species#Designator.', project_id: $project_id),
            'Depository' => Predicate.find_or_create_by(name: 'Species:Depository', definition: 'The verbatim value in Species#Depository.', project_id: $project_id),
            'TypeNumber' => Predicate.find_or_create_by(name: 'Species:TypeNumber', definition: 'The verbatim value in Species#TypeNumber.', project_id: $project_id),
            'DeposB' => Predicate.find_or_create_by(name: 'Species:DeposB', definition: 'The verbatim value in Species#DeposB.', project_id: $project_id),
            'DeposC' => Predicate.find_or_create_by(name: 'Species:DeposC', definition: 'The verbatim value in Species#DeposC.', project_id: $project_id),
            'Species:CurrStat' => Predicate.find_or_create_by(name: 'Species:CurrStat', definition: 'The verbatim value in Species#CurrStat.', project_id: $project_id),
            'Status:Meaning' => Predicate.find_or_create_by(name: 'Status:Meaning', definition: 'The verbatim value in Status#Meaning.', project_id: $project_id)
        }.freeze
        topics = {
            'Figures' => Topic.find_or_create_by(name: 'Figures', definition: 'Original source has figures.', project_id: $project_id)
        }

        status_type = {
            'AB' => 'Aberration',
            'FM' => 'Form',
            'NS' => 'New species',
            'NT' => 'New species, invalid spelling',
            'NU' => 'New species, misspelt generic name',
            'NW' => 'New species, misspelt subgeneric name',
            'NY' => 'New species, generic placement queried',
            'RN' => 'Replacement name',
            'SS' => 'Subspecies',
            'UE' => 'Unjustified emendation',
            'UN' => 'Unjustified emendation, new combination',
            'UR' => 'Unnecessary replacement name',
            'VM' => 'Variety, misspelt species name',
            'VR' => 'Variety',
            'VS' => 'Valid species'
        }
        classification_type = {
            'AB' => 'TaxonNameClassification::Iczn::Unavailable::Excluded::Infrasubspecific',
            'FM' => 'TaxonNameClassification::Iczn::Unavailable::VarietyOrFormAfter1960',
            'VR' => 'TaxonNameClassification::Iczn::Unavailable::VarietyOrFormAfter1960',
            'FS' => 'TaxonNameClassification::Iczn::Fossil',
            'ND' => 'TaxonNameClassification::Iczn::Available::Valid::NomenDubium',
            'NN' => 'TaxonNameClassification::Iczn::Unavailable::NomenNudum',
        }


        file.each_with_index do |row, i|
          print "\r#{i}"
          taxon = find_taxon_ucd(row['TaxonCode'])
          ref = find_source_id_ucd(row['RefCode'])
          print "\n TaxonCode: #{row['TaxonCode']} not found \n" if !row['TaxonCode'].blank? && taxon.nil?
          unless taxon.nil?
            unless ref.nil?
              c = taxon.citations.create(source_id: ref, pages: row['PageRef'], is_original: true)
              if c.valid?
                c.citation_topics.find_or_create_by(topic: topics['Figures'], project_id: $project_id) unless row['Figures'].blank?
              end
            end
            taxon.notes.create(text: row['Notes']) unless row['Notes'].blank?
            taxon.data_attributes.create(type: 'InternalAttribute', predicate: keywords['Status:Meaning'], value: status_type[row['CurrStat']]) unless status_type[row['CurrStat']].nil?
            taxon.data_attributes.create(type: 'InternalAttribute', predicate: keywords['Species:Country'], value: @data.countries[row['Country'] + '|' + row['State']]) unless @data.countries[row['Country'] + '|' + row['State']].nil?
            taxon.data_attributes.create(type: 'InternalAttribute', predicate: keywords['Coll:Depository'], value: @data.collections[row['Depository']]) unless @data.collections[row['Depository']].nil?
            keywords.each_key do |k|
              taxon.data_attributes.create(type: 'InternalAttribute', predicate: keywords[k], value: row[k]) unless row[k].blank?
            end
            taxon.taxon_name_classifications.create(type: classification_type[row['CurrStat']]) unless classification_type[row['CurrStat']].nil?
          end
        end
      end

      def handle_h_fam_ucd
        keywords = {
            'SuperFam' => Predicate.find_or_create_by(name: 'H-Fam:SuperFam', definition: 'The verbatim value in H-Fam#SuperFam.', project_id: $project_id)
        }.freeze

        path = @args[:data_directory] + 'H-FAM.txt'
        print "\nHandling H-FAM\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')
        file.each_with_index do |row, i|
          print "\r#{i}"
          name = row['Order'].to_s.gsub('.', '')
          if name.blank?
            taxon = @root
          else
            taxon = Protonym.find_or_create_by(name: name, parent: @root, rank_class: 'NomenclaturalRank::Iczn::HigherClassificationGroup::Order', project_id: $project_id)
            if row['Family'] =~/^[A-Z]\w*aceae/
              taxon.rank_class = 'NomenclaturalRank::Icn::HigherClassificationGroup::Order'
              taxon.save
            end
          end
          parent = taxon
          if row['SuperFam'] =~/^[A-Z]\w*oidea/
            name = row['SuperFam']
            taxon = Protonym.find_or_create_by(name: name, parent: parent, rank_class: 'NomenclaturalRank::Iczn::FamilyGroup::Superfamily', project_id: $project_id)
          end
          parent = taxon
          name = row['Family'].to_s.gsub(' indet.', '').gsub(' (part)', '').gsub(' ', '')
          if row['Family'] =~/^[A-Z]\w*idae/
            taxon = Protonym.find_or_create_by(name: name, parent: parent, rank_class: 'NomenclaturalRank::Iczn::FamilyGroup::Family', project_id: $project_id)
          elsif row['Family'] =~/^[A-Z]\w*aceae/
              taxon = Protonym.find_or_create_by(name: name, parent: parent, rank_class: 'NomenclaturalRank::Icn::FamilyGroup::Family', project_id: $project_id)
          elsif row['Family'] == 'Slime mould'
            taxon = Protonym.find_or_create_by(name: 'Slime', parent: @root, rank_class: 'NomenclaturalRank::Iczn::HigherClassificationGroup::Kingdom', project_id: $project_id)
          end
          taxon.data_attributes.create(type: 'InternalAttribute', predicate: keywords['SuperFam'], value: row['SuperFam']) if !row['SuperFam'].blank? && !taxon.parent.nil? && taxon.parent.rank_class != 'NomenclaturalRank::Iczn::FamilyGroup::Superfamily' && taxon.data_attributes.nil?
          taxon.identifiers.find_or_create_by(type: 'Identifier::Local::Import', namespace: @data.keywords['host_family_id'], identifier: row['Code']) if !row['Code'].blank?
        end

      end

      def handle_hostfam_ucd
        keywords = {
            'HosNumber' => Predicate.find_or_create_by(name: 'Hostfam:HosNumber', definition: 'The verbatim value in Hostfam#HosNumber.', project_id: $project_id)
        }.freeze

        path = @args[:data_directory] + 'HOSTFAM.txt'
        print "\nHandling HOSTFAM\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')
        file.each_with_index do |row, i|
          print "\r#{i}"
          parent = find_host_family_id_ucd('PrimHosFam') || @root.id
          taxon = Protonym.find_or_create_by(name: row['HosGenus'], parent_id: parent, rank_class: 'NomenclaturalRank::Iczn::GenusGroup::Genus', project_id: $project_id)
          parent = taxon.id
          unless row['HosSpecies'].blank?
            taxon = Protonym.find_or_create_by(name: row['HosSpecies'], rank_class: 'NomenclaturalRank::Iczn::SpeciesGroup::Species', parent_id: parent, project_id: $project_id)
          end
          unless row['HosAuthor'].blank?
            taxon.verbatim_author = row['HosAuthor']
            taxon.save if taxon.valid?
          end
          taxon.data_attributes.create(type: 'InternalAttribute', predicate: keywords['HosNumber'], value: row['HosNumber']) if !row['HosNumber'].blank? && taxon.data_attributes.nil?
        end

      end

      def handle_keywords_ucd
        tags = {'1' => Keyword.find_or_create_by(name: '1', definition: 'Taxonomic', project_id: $project_id),
                '2' => Keyword.find_or_create_by(name: '2', definition: 'Biological', project_id: $project_id),
                '3' => Keyword.find_or_create_by(name: '3', definition: 'Economic', project_id: $project_id),
        }.freeze
        path = @args[:data_directory] + 'KEYWORDS.txt'
        print "\nHandling KEYWORDS\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')
        file.each_with_index do |row, i|
          print "\r#{i}"
          definition = row['Meaning'].to_s.length < 4 ? row['Meaning'] + '.' : row['Meaning']
          topic = Topic.find_or_create_by(name: row['KeyWords'], definition: definition, project_id: $project_id)
          topic.tags.find_or_create_by(keyword: tags[row['Category']]) unless row['Category'].blank?
          @data.topics[row['KeyWords']] = topic
        end
      end

      def handle_hknew_ucd
        path = @args[:data_directory] + 'HKNEW.txt'
        print "\nHandling HKNEW\n"
        raise "file #{path} not found" if not File.exists?(path)
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'iso-8859-1:UTF-8')
        file.each_with_index do |row, i|
          print "\r#{i}"
          taxon = find_taxon_ucd(row['TaxonCode'])
          print "\n TaxonCode: #{row['TaxonCode']} not found \n" if !row['TaxonCode'].blank? || taxon.nil?

          ref = find_source_id_ucd(row['RefCode'])

          c = taxon.citations.find_or_create_by(source_id: ref, pages: row['PageRef']) if !ref.nil? && !taxon.nil?
          c.citation_topics.find_or_create_by(topic: @data.topics[row['Keyword']], project_id: $project_id) unless row['Keywords'].blank?

        end
      end




      def find_taxon_id_ucd(key)
        @data.taxon_codes[key.to_s] || Identifier.where(cached: 'UCD_Taxon_ID ' + key.to_s, identifier_object_type: 'TaxonName', project_id: $project_id).limit(1).pluck(:identifier_object_id).first
      end

      def find_family_id_ucd(key)
        @data.families[key.to_s] || Identifier.where(cached: 'UCD_Family_ID ' + key.to_s, identifier_object_type: 'TaxonName', project_id: $project_id).limit(1).pluck(:identifier_object_id).first
      end

      def find_host_family_id_ucd(key)
        @data.families[key.to_s] || Identifier.where(cached: 'UCD_Host_Family_ID ' + key.to_s, identifier_object_type: 'TaxonName', project_id: $project_id).limit(1).pluck(:identifier_object_id).first
      end

      def find_taxon_ucd(key)
        Identifier.find_by(cached: 'UCD_Taxon_ID ' + key.to_s, identifier_object_type: 'TaxonName', project_id: $project_id).try(:identifier_object)
      end

      def find_source_ucd(key)
        Identifier.find_by(cached: 'UCD_RefCode ' + key.to_s, identifier_object_type: 'Source', project_id: $project_id).try(:identifier_object)
      end

      def find_source_id_ucd(key)
        @data.references[key.to_s] || Identifier.where(cached: 'UCD_RefCode ' + key.to_s, identifier_object_type: 'Source', project_id: $project_id).limit(1).pluck(:identifier_object_id).first
      end


    end
  end
end



