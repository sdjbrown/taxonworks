require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe TaxonDeterminationsController, type: :controller do
  before(:each) {
    sign_in
  }

  # This should return the minimal set of attributes required to create a valid
  # Georeference. As you add validations to Georeference be sure to
  let(:otu) { FactoryBot.create(:valid_otu) }
  let(:specimen) { FactoryBot.create(:valid_specimen) }
  let(:valid_attributes) {
    strip_housekeeping_attributes( {otu_id: otu.to_param, taxon_determination_object_id: specimen.to_param, taxon_determination_object_type: 'CollectionObject'} )
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # TaxonDeterminationsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe 'GET index' do
    it 'assigns a projects recent taxon_determinations as @recent_objects' do
      taxon_determination = TaxonDetermination.create! valid_attributes
      get :index, params: {}, session: valid_session
      expect(assigns(:recent_objects)).to eq([taxon_determination])
    end
  end

  describe 'GET show' do
    it 'assigns the requested taxon_determination as @taxon_determination' do
      taxon_determination = TaxonDetermination.create! valid_attributes
      get :show, params: {id: taxon_determination.to_param}, session: valid_session
      expect(assigns(:taxon_determination)).to eq(taxon_determination)
    end
  end

  describe 'GET new' do
    it 'assigns a new taxon_determination as @taxon_determination' do
      get :new, params: {}, session: valid_session
      expect(assigns(:taxon_determination)).to be_a_new(TaxonDetermination)
    end
  end

  describe 'GET edit' do
    it 'assigns the requested taxon_determination as @taxon_determination' do
      taxon_determination = TaxonDetermination.create! valid_attributes
      get :edit, params: {id: taxon_determination.to_param}, session: valid_session
      expect(assigns(:taxon_determination)).to eq(taxon_determination)
    end
  end

  describe 'POST create' do
    describe 'with valid params' do
      it 'creates a new TaxonDetermination' do
        expect {
          post :create, params: {taxon_determination: valid_attributes}, session: valid_session
        }.to change(TaxonDetermination, :count).by(1)
      end

      it 'assigns a newly created taxon_determination as @taxon_determination' do
        post :create, params: {taxon_determination: valid_attributes}, session: valid_session
        expect(assigns(:taxon_determination)).to be_a(TaxonDetermination)
        expect(assigns(:taxon_determination)).to be_persisted
      end

      it 'redirects to the created taxon_determination' do
        post :create, params: {taxon_determination: valid_attributes}, session: valid_session
        expect(response).to redirect_to(TaxonDetermination.last)
      end
    end

    describe 'with invalid params' do
      it 'assigns a newly created but unsaved taxon_determination as @taxon_determination' do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(TaxonDetermination).to receive(:save).and_return(false)
        post :create, params: {taxon_determination: {taxon_determination_object_id: 'invalid value'}}, session: valid_session
        expect(assigns(:taxon_determination)).to be_a_new(TaxonDetermination)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(TaxonDetermination).to receive(:save).and_return(false)
        post :create, params: {taxon_determination: {taxon_determination_object_id: 'invalid value'}}, session: valid_session
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT update' do
    describe 'with valid params' do
      it 'updates the requested taxon_determination' do
        otu2 = FactoryBot.create(:valid_otu)
        taxon_determination = TaxonDetermination.create! valid_attributes
        # Assuming there are no other taxon_determinations in the database, this
        # specifies that the TaxonDetermination created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        update_params = ActionController::Parameters.new({otu_id: otu2.to_param}).permit(:otu_id)
        expect_any_instance_of(TaxonDetermination).to receive(:update).with(update_params)
        put :update, params: {id: taxon_determination.to_param, taxon_determination: {otu_id: otu2.id}}, session: valid_session
      end

      it 'assigns the requested taxon_determination as @taxon_determination' do
        taxon_determination = TaxonDetermination.create! valid_attributes
        put :update, params: {id: taxon_determination.to_param, taxon_determination: valid_attributes}, session: valid_session
        expect(assigns(:taxon_determination)).to eq(taxon_determination)
      end

      it 'redirects to the taxon_determination' do
        taxon_determination = TaxonDetermination.create! valid_attributes
        put :update, params: {id: taxon_determination.to_param, taxon_determination: valid_attributes}, session: valid_session
        expect(response).to redirect_to(taxon_determination)
      end
    end

    describe 'with invalid params' do
      it 'assigns the taxon_determination as @taxon_determination' do
        taxon_determination = TaxonDetermination.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(TaxonDetermination).to receive(:save).and_return(false)
        put :update, params: {id: taxon_determination.to_param, taxon_determination: {taxon_determination_object_id: 'invalid value'}}, session: valid_session
        expect(assigns(:taxon_determination)).to eq(taxon_determination)
      end

      it "re-renders the 'edit' template" do
        taxon_determination = TaxonDetermination.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(TaxonDetermination).to receive(:save).and_return(false)
        put :update, params: {id: taxon_determination.to_param, taxon_determination: {taxon_determination_object_id: 'invalid value'}}, session: valid_session
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE destroy' do
    it 'destroys the requested taxon_determination' do
      taxon_determination = TaxonDetermination.create! valid_attributes
      expect {
        delete :destroy, params: {id: taxon_determination.to_param}, session: valid_session
      }.to change(TaxonDetermination, :count).by(-1)
    end

    it 'redirects to the taxon_determinations list' do
      taxon_determination = TaxonDetermination.create! valid_attributes
      delete :destroy, params: {id: taxon_determination.to_param}, session: valid_session
      expect(response).to redirect_to(taxon_determinations_url)
    end
  end

end
