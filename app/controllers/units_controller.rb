class UnitsController < ApplicationController
  before_action :set_unit, only: [:show, :edit, :update, :destroy, :remove_employee, :add_employee]

  # GET /units
  # GET /units.json
  def index
    @units = Unit.all
  end

  # GET /units/1
  # GET /units/1.json
  def show
  end

  # GET /units/new
  def new
    @unit = Unit.new
  end

  # GET /units/1/edit
  def edit
  end

  # POST /units
  # POST /units.json
  def create
    @unit = Unit.new(unit_params)
    respond_to do |format|
      if @unit.save
        Unit.transaction do
          auth = Signet::Rails::Factory.create_from_env :google, request.env
          client = Google::APIClient.new
          client.authorization = auth
          plusDomain = client.discovered_api('plusDomains')
          @result = client.execute(:api_method => plusDomain.circles.insert,
            :parameters => {'userId' => 'me'},
            :body =>MultiJson.dump('displayName' => @unit.name),
            :headers => {'Content-Type' => 'application/json'}
          )
          @unit.update_column(:circle_id, @result.data.id)
        end
        format.html { redirect_to @unit, notice: 'Unit was successfully created.' }
        format.json { render action: 'show', status: :created, location: @unit }
      else
        format.html { render action: 'new' }
        format.json { render json: @unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /units/1
  # PATCH/PUT /units/1.json
  def update
    respond_to do |format|
      if @unit.update(unit_params)
        format.html { redirect_to @unit, notice: 'Unit was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /units/1
  # DELETE /units/1.json
  def destroy
    @unit.destroy
    respond_to do |format|
      format.html { redirect_to units_url }
      format.json { head :no_content }
    end
  end
  
  def remove_employee
    employee = Employee.find(params[:employee_id])
    Unit.transaction do
      auth = Signet::Rails::Factory.create_from_env :google, request.env
      client = Google::APIClient.new
      client.authorization = auth
      plusDomain = client.discovered_api('plusDomains')
      @result = client.execute(
        :api_method => plusDomain.circles.remove_people,
        :parameters => {'circleId' => @unit.circle_id, 'email' => employee.email}
      )
      @unit.employees.delete employee
    end
    redirect_to :back
  end
  
  def add_employee
    employee = Employee.find(params[:employee_id])
    Unit.transaction do
      auth = Signet::Rails::Factory.create_from_env :google, request.env
      client = Google::APIClient.new
      client.authorization = auth
      plusDomain = client.discovered_api('plusDomains')
        @result = client.execute(
          :api_method => plusDomain.circles.add_people,
          :parameters => {'circleId' => @unit.circle_id, 'email' => employee.email}
        )
      @unit.employees << employee
    end
    redirect_to :back
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_unit
      @unit = Unit.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def unit_params
      params.require(:unit).permit(:name, :circle_id)
    end
end
