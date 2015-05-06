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

RSpec.describe DepictionsController, type: :controller do

  before(:each) {
    sign_in
  }


  let(:specimen) { FactoryGirl.create(:valid_specimen) }

  # This should return the minimal set of attributes required to create a valid
  # Depiction. As you add validations to Depiction, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) { 
    {
      depiction_object_type: 'CollectionObject',
      depiction_object_id: specimen.id,
      image_attributes: { image_file: fixture_file_upload((Rails.root + 'spec/files/images/tiny.png'), 'image/png')}
    }
  }

  let(:invalid_attributes) { 
    {
      depiction_object_type: 'CollectionObject',
      depiction_object_id: nil,
      image_attributes: { image_file: fixture_file_upload((Rails.root + 'spec/files/images/tiny.png'), 'image/png')}
    }
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # DepictionsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "assigns all depictions as @recent_objects" do
      depiction = Depiction.create! valid_attributes
      get :index, {}, valid_session
      expect(assigns(:recent_objects)).to eq([depiction])
    end
  end

  describe "GET #show" do
    it "assigns the requested depiction as @depiction" do
      depiction = Depiction.create! valid_attributes
      get :show, {:id => depiction.to_param}, valid_session
      expect(assigns(:depiction)).to eq(depiction)
    end
  end

  describe "GET #new" do
    it "assigns a new depiction as @depiction" do
      get :new, {}, valid_session
      expect(assigns(:depiction)).to be_a_new(Depiction)
    end
  end

  describe "GET #edit" do
    it "assigns the requested depiction as @depiction" do
      depiction = Depiction.create! valid_attributes
      get :edit, {:id => depiction.to_param}, valid_session
      expect(assigns(:depiction)).to eq(depiction)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Depiction" do
        expect {
          post :create, {:depiction => valid_attributes}, valid_session
        }.to change(Depiction, :count).by(1)
      end

      it "assigns a newly created depiction as @depiction" do
        post :create, {:depiction => valid_attributes}, valid_session
        expect(assigns(:depiction)).to be_a(Depiction)
        expect(assigns(:depiction)).to be_persisted
      end

      it "redirects to the created depiction" do
        post :create, {:depiction => valid_attributes}, valid_session
        expect(response).to redirect_to(Depiction.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved depiction as @depiction" do
        post :create, {:depiction => invalid_attributes}, valid_session
        expect(assigns(:depiction)).to be_a_new(Depiction)
      end

      it "re-renders the 'new' template" do
        post :create, {:depiction => invalid_attributes}, valid_session
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:specimen2) { FactoryGirl.create(:valid_specimen) }

      let(:new_attributes) {
        { depiction_object_id: specimen2.id }
      }

      it "updates the requested depiction" do
        depiction = Depiction.create! valid_attributes
        put :update, {:id => depiction.to_param, :depiction => new_attributes}, valid_session
        depiction.reload
        expect(depiction.depiction_object_id).to eq(specimen2.id) 
      end

      it "assigns the requested depiction as @depiction" do
        depiction = Depiction.create! valid_attributes
        put :update, {:id => depiction.to_param, :depiction => valid_attributes}, valid_session
        expect(assigns(:depiction)).to eq(depiction)
      end

      it "redirects to the depiction" do
        depiction = Depiction.create! valid_attributes
        put :update, {:id => depiction.to_param, :depiction => valid_attributes}, valid_session
        expect(response).to redirect_to(depiction)
      end
    end

    context "with invalid params" do
      it "assigns the depiction as @depiction" do
        depiction = Depiction.create! valid_attributes
        put :update, {:id => depiction.to_param, :depiction => invalid_attributes}, valid_session
        expect(assigns(:depiction)).to eq(depiction)
      end

      it "re-renders the 'edit' template" do
        depiction = Depiction.create! valid_attributes
        put :update, {:id => depiction.to_param, :depiction => invalid_attributes}, valid_session
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested depiction" do
      depiction = Depiction.create! valid_attributes
      expect {
        delete :destroy, {:id => depiction.to_param}, valid_session
      }.to change(Depiction, :count).by(-1)
    end

    it "redirects to the depictions list" do
      depiction = Depiction.create! valid_attributes
      delete :destroy, {:id => depiction.to_param}, valid_session
      expect(response).to redirect_to(depictions_url)
    end
  end

end
