class Api::V1::AppointmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_appointment, only: %i[show update]

  # GET /appointments
  def index
    slug_id = get_slug_id
    params[:slug_id] = slug_id
    if params[:search].blank?
      @appointments = Appointment.order(order_and_direction).page(page).per(per_page)
                                 .where(slug_id: params[:slug_id])
    else
      @appointments = Appointment.joins(:contact).order(order_and_direction)
                                 .page(page).per(per_page)
                                 .where(slug_id: params[:slug_id])
                                 .where(["(lower(label) like ?
                                  or lower(contacts.name) like ? )",
                                  '%' + params[:search].downcase + '%',
                                  '%' + params[:search].downcase + '%',
                                  ])
    end
    set_pagination_headers :appointments

    json_string = AppointmentSerializer.new(@appointments, include: %i[property contact])
                                       .serializable_hash.to_json
    render json: json_string
  end

  # GET /appointments-calendar
  def calendar_appointments
    slug_id = get_slug_id
    params[:slug_id] = slug_id
    @appointments = Appointment.where(slug_id: params[:slug_id])
                               .where(start_time: params[:firstDay]..params[:lastDay])


    json_string = AppointmentSerializer.new(@appointments, include: %i[property contact])
                                       .serializable_hash.to_json
    render json: json_string
  end

  # GET /appointments/1
  def show
    json_string = AppointmentSerializer.new(@appointment, include: %i[property contact])
                                       .serializable_hash.to_json
    render json: json_string
  end

  # POST /appointments
  def create
    slug_id = get_slug_id
    params[:slug_id] = slug_id
    date_params = params[:start_time].to_datetime
    if date_params < Date.today
      render json: { code: 'E002', message: " Appointment date can't be less than today"}, status: :not_acceptable
    else
    @appointment = Appointment.new(appointment_params)
    if @appointment.save

      if @appointment.important
        users = User.where(slug_id: slug_id, role: 'admin')
        users_id = users.collect(&:email)
        users_id.map { |id| create_notification('create appointment', id, @appointment )}
      end

      render json: @appointment, status: :created
    else
      render json: @appointment.errors, status: :unprocessable_entity
    end
    end
  end

  # PATCH/PUT /appointments/1
  def update
    slug_id = get_slug_id
    date_params = params[:start_time].to_datetime
    if date_params < Date.today
      render json: { code: 'E002', message: " Appointment date can't be less than today"}, status: :not_acceptable
    else
    if @appointment.update(appointment_params)
      if @appointment.important
      users = User.where(slug_id: slug_id, role: 'admin')
      users_id = users.collect(&:email)
      users_id.map { |id| create_notification('update appointment', id, @appointment )}
      end
      render json: @appointment
    else
      render json: @appointment.errors, status: :unprocessable_entity
    end
    end
  end

  # DELETE /appointments/1
  def destroy
    ids = params[:id].split(',')
    if ids.length != 1
      Appointment.where(id: params[:id].split(',')).destroy_all
    else
      Appointment.find(params[:id]).destroy
    end

  rescue ActiveRecord::InvalidForeignKey => e
    render json: {
        code: 'E001',
        message: 'This appointment has a property'
    },  status: :not_acceptable



  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def appointment_params
    params.permit(:label, :description, :status, :contact_id, :slug_id,
                  :property_id, :service, :user_id, :start_time, :important)
  end
  
  
end
