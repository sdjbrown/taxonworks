require 'rails_helper'

describe BatchLoad::Import::Otus::DataAttributesInterpreter, type: :model do

  let(:file_ph_1) { 'spec/files/batch/otu/da_ph_1.tsv' }
  let(:file_ph_2) { 'spec/files/batch/otu/da_ph_2.tsv' }
  let(:file_name) { 'spec/files/batch/otu/OtuTest.tsv' }
  let(:names) do
    bingo = import
    bingo.create
  end
  let(:user) { User.find(1) }
  let(:project) { Project.find(1) }

  let(:upload_file) { fixture_file_upload(file_name) }
  let(:import) { BatchLoad::Import::Otus.new(project_id: project.id,
                                             user_id:    user.id,
                                             file:       upload_file)
  }

  context 'scanning tsv lines to evaluate data' do

    let(:upload_file_2) { fixture_file_upload(file_ph_2) }
    let(:import_2) { BatchLoad::Import::Otus::DataAttributesInterpreter.new(project_id: project.id,
                                                                            user_id:    user.id,
                                                                            file:       upload_file_2)
    }

    context 'file provided' do
      it 'loads reviewed data' do
        names
        bingo = import_2
        expect(Otu.count).to eq(8)
      end
    end
  end

  context 'building objects from valid tsv lines' do

    let(:setup) { names
    csv1 = CSV.read(file_name, {headers:           true,
                                header_converters: :downcase,
                                col_sep:           "\t",
                                encoding:          'UTF-8'})
    csv1.each do |row|
      ident = row[0]
      case ident
      when 'americana' # create an otu to find later
        Otu.create(name: ident)
      else
      end
    end
    }
    let(:user) { User.find(1) }
    let(:project) { Project.find(1) }

    let(:upload_file) { fixture_file_upload(file_name) }
    let(:import) { BatchLoad::Import::Otus.new(project_id: project.id,
                                               user_id:    user.id,
                                               file:       upload_file)
    }

    context 'file provided' do
      xit 'loads reviewed data' do
        setup
        expect(Otu.count).to eq(1)
        bingo = import
        expect(bingo).to be_truthy
        bingo.create
        expect(Otu.count).to eq(7)
      end
    end
  end
end
