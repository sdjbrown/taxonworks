require 'spec_helper'

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

describe LoanItemsController do

  # This should return the minimal set of attributes required to create a valid
  # LoanItem. As you add validations to LoanItem, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) { strip_housekeeping_attributes( FactoryGirl.build(:valid_loan_item).attributes) }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # LoanItemsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET index" do
    it "assigns all loan_items as @loan_items" do
      loan_item = LoanItem.create! valid_attributes
      get :index, {}, valid_session
      assigns(:loan_items).should eq([loan_item])
    end
  end

  describe "GET show" do
    it "assigns the requested loan_item as @loan_item" do
      loan_item = LoanItem.create! valid_attributes
      get :show, {:id => loan_item.to_param}, valid_session
      assigns(:loan_item).should eq(loan_item)
    end
  end

  describe "GET new" do
    it "assigns a new loan_item as @loan_item" do
      get :new, {}, valid_session
      assigns(:loan_item).should be_a_new(LoanItem)
    end
  end

  describe "GET edit" do
    it "assigns the requested loan_item as @loan_item" do
      loan_item = LoanItem.create! valid_attributes
      get :edit, {:id => loan_item.to_param}, valid_session
      assigns(:loan_item).should eq(loan_item)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new LoanItem" do
        expect {
          post :create, {:loan_item => valid_attributes}, valid_session
        }.to change(LoanItem, :count).by(1)
      end

      it "assigns a newly created loan_item as @loan_item" do
        post :create, {:loan_item => valid_attributes}, valid_session
        assigns(:loan_item).should be_a(LoanItem)
        assigns(:loan_item).should be_persisted
      end

      it "redirects to the created loan_item" do
        post :create, {:loan_item => valid_attributes}, valid_session
        response.should redirect_to(LoanItem.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved loan_item as @loan_item" do
        # Trigger the behavior that occurs when invalid params are submitted
        LoanItem.any_instance.stub(:save).and_return(false)
        post :create, {:loan_item => {  }}, valid_session
        assigns(:loan_item).should be_a_new(LoanItem)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        LoanItem.any_instance.stub(:save).and_return(false)
        post :create, {:loan_item => {  }}, valid_session
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested loan_item" do
        loan_item = LoanItem.create! valid_attributes
        # Assuming there are no other loan_items in the database, this
        # specifies that the LoanItem created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        LoanItem.any_instance.should_receive(:update).with({ "these" => "params" })
        put :update, {:id => loan_item.to_param, :loan_item => { "these" => "params" }}, valid_session
      end

      it "assigns the requested loan_item as @loan_item" do
        loan_item = LoanItem.create! valid_attributes
        put :update, {:id => loan_item.to_param, :loan_item => valid_attributes}, valid_session
        assigns(:loan_item).should eq(loan_item)
      end

      it "redirects to the loan_item" do
        loan_item = LoanItem.create! valid_attributes
        put :update, {:id => loan_item.to_param, :loan_item => valid_attributes}, valid_session
        response.should redirect_to(loan_item)
      end
    end

    describe "with invalid params" do
      it "assigns the loan_item as @loan_item" do
        loan_item = LoanItem.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        LoanItem.any_instance.stub(:save).and_return(false)
        put :update, {:id => loan_item.to_param, :loan_item => {  }}, valid_session
        assigns(:loan_item).should eq(loan_item)
      end

      it "re-renders the 'edit' template" do
        loan_item = LoanItem.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        LoanItem.any_instance.stub(:save).and_return(false)
        put :update, {:id => loan_item.to_param, :loan_item => {  }}, valid_session
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested loan_item" do
      loan_item = LoanItem.create! valid_attributes
      expect {
        delete :destroy, {:id => loan_item.to_param}, valid_session
      }.to change(LoanItem, :count).by(-1)
    end

    it "redirects to the loan_items list" do
      loan_item = LoanItem.create! valid_attributes
      delete :destroy, {:id => loan_item.to_param}, valid_session
      response.should redirect_to(loan_items_url)
    end
  end

end
