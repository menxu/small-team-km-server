class Api::DataItemsController < ApplicationController
  before_filter :login_required
  before_filter :per_load
  def per_load
    @data_item = DataItem.find(params[:id]) if params[:id]
    @data_list = DataList.find(params[:data_list_id]) if params[:data_list_id]
  end

  def index
    render :json => @data_list.data_items.map{|data_item|data_item.to_hash}
  end

  def create
    data_item = @data_list.create_item(params[:kind], params[:title], params[:value])
    render :json => data_item.to_hash
  rescue Exception => ex
    render :text => ex.message,:status => 422
  end

  def update
    @data_item.update_by_params(params[:title], params[:value])
    render :json => @data_item.to_hash
  rescue Exception => ex
    render :text => ex.message,:status => 422
  end

  def destroy
    @data_item.destroy
    render :status => 200
  end

  def order
    data_list = @data_item.data_list
    insert_at = data_list.data_items.find(params[:insert_at]).position
    @data_item.insert_at(insert_at)
    data_items = data_list.data_items.where("position >= #{@data_item.position}")

    render :json => data_items.map{|item|{:id => item.id, :position => item.position}}
  rescue ActiveRecord::RecordNotFound => ex
    render :text=>"没有找到 ID 是 #{params[:insert_at]} 的 data_item",:status => 404
  end
end