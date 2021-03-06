class HomeworksController < ApplicationController
  before_action :set_homework, only: [:show, :edit, :update, :destroy]

  def mkdir(directory)
    token = directory.split('/')
    1.upto(token.size)  do |n|
      dir = token[0...n].join('/')
      Dir.mkdir(dir) unless Dir.exist? (dir)
    end
  end

  # GET /homeworks
  # GET /homeworks.json
  def index
    @homeworks = Homework.all
  end

  # GET /homeworks/1
  # GET /homeworks/1.json
  def show
  end

  # GET /homeworks/new
  def new
    @homework = Homework.new
  end

  # GET /homeworks/1/edit
  def edit
  end

  def create_homework
    if session[:user_role] != 'instructor'
      redirect_to login_path
    else
      @user = User.find(session[:user_id])
    end
  end

  def homework_history
    if session[:user_role] != 'instructor'
      redirect_to login_path
    else
      @user = User.find(session[:user_id])
    end
  end

  def time_diff_string(diff_sec)
    mm, ss = diff_sec.divmod(60)
    hh, mm = mm.divmod(60)
    dd, hh = hh.divmod(24)
    diff_string = "%d days, %d hours, %d minutes and %d seconds" % [dd, hh, mm, ss]
    return diff_string
  end

  def view_assignment
    if session[:user_role] != 'instructor'
      redirect_to login_path
    else
      @user = User.find(session[:user_id])
      @course = Course.find(params[:course_id])
      @homework = Homework.find(params[:homework_id])
      homework_timeLeft = @homework.hw_due_time - Time.zone.now
      if homework_timeLeft < 0
        @time_left = '-' + time_diff_string(-homework_timeLeft)
      else
        @time_left = time_diff_string(homework_timeLeft)
      end
      @user_in_course = @course.users.where(user_role: 'student').size
      @user_valid = Submission.where(course_id: params[:course_id], homework_id: params[:homework_id]).select(:user_id).map(&:user_id).uniq.size
      grade_byUser = Submission.select("MAX(sm_grade)").group(:user_id).where(course_id: params[:course_id], homework_id: params[:homework_id]).maximum(:sm_grade)
      if grade_byUser.values.count == 0
        @average_grade = 0
      else
        @average_grade = (grade_byUser.values.sum / grade_byUser.values.count).round(3)
      end
    end
  end

  def edit_homework
    if session[:user_role] != 'instructor'
      redirect_to login_path
    else
      @user = User.find(session[:user_id])
      @course = Course.find(params[:course_id])
      @homework = Homework.find(params[:homework_id])
      #@homework.hw_due_time.to_s.split('')

      @due_split = @homework[:hw_due_time].to_s.split(' ')
      @due_date = @due_split[0].split('-')
      @due_time = @due_split[1].split(':')
      @due_date_times = @due_date + @due_time

      @release_split = @homework[:hw_release_time].to_s.split(' ')
      @release_date = @release_split[0].split('-')
      @release_time = @release_split[1].split(':')
      @release_date_times = @release_date + @release_time

    end
  end

  def view_student_record
    if session[:user_role] != 'instructor'
      redirect_to login_path
    else
      @user = User.find(session[:user_id])
      @username = User.find(session[:user_id]).user_name
      @student = User.find(params[:student_id])
      @homework_grades = Submission.select(:sm_grade).group(:homework_id)
    end
    #@submissions = Submission.where(:course_id => params[:course_id]).where(:homework_id => params[:homework_id])
    #@homework = Homework.find(params[:homework_id])
  end


  def create
    @user = User.find(session[:user_id])
    @course = Course.find(params[:course_id])

    if (params[:edit_homework_flag].nil?)
      @homework = Homework.new
      @homework[:hw_name] = params[:hw_name]
      @courseToHomework = CourseToHomework.new
    else
      @homework = Homework.find(params[:homework_id])
      @courseToHomework = CourseToHomework.where(:course_id => params[:course_id], :homework_id => params[:homework_id]).first
    end


    @homework[:hw_description] = params[:hw_description]
    due_time = Time.zone.local(params[:time]["due_time(1i)"].to_i,
                               params[:time]["due_time(2i)"].to_i,
                               params[:time]["due_time(3i)"].to_i,
                               params[:time]["due_time(4i)"].to_i,
                               params[:time]["due_time(5i)"].to_i)
    release_time = Time.zone.local(params[:time]["release_time(1i)"].to_i,
                                   params[:time]["release_time(2i)"].to_i,
                                   params[:time]["release_time(3i)"].to_i,
                                   params[:time]["release_time(4i)"].to_i,
                                   params[:time]["release_time(5i)"].to_i)
    @homework[:hw_release_time] = release_time
    @homework[:hw_due_time] = due_time 
    @homework.save


    directory = './UPLOAD/' + @course[:course_name] + '/' + @homework[:hw_name] + '/'
    directory = directory.tr(' ', '_')

    mkdir(directory)
    if !params[:testcase_input].nil?
      File.open(directory + 'input', "w") { |f| f.write(params[:testcase_input].read.force_encoding('UTF-8')) }
    end

    if !params[:testcase_output].nil?
      File.open(directory + 'output', "w") { |f| f.write(params[:testcase_output].read.force_encoding('UTF-8')) }
    end


    @courseToHomework.course_id = params[:course_id]
    @courseToHomework.homework_id = @homework.id 
    @courseToHomework[:hw_test_case_dir] = directory
    @courseToHomework.save

    redirect_to "/show_instructor"
  end

  # PATCH/PUT /homeworks/1
  # PATCH/PUT /homeworks/1.json


  # DELETE /homeworks/1
  # DELETE /homeworks/1.json

  def destroy
    @homework.destroy

    respond_to do |format|
      format.html { redirect_to homeworks_url, notice: 'Homework was successfully destroyed.' }
      format.json { head :no_content }
    end
  end


  def destroy_homework
    @course_to_homework = CourseToHomework.where(course_id: params[:course_id], homework_id: params[:homework_id]).first
    @course_to_homework.destroy
    @remainder = CourseToHomework.where(homework_id: params[:homework_id]).first
    if @remainder.nil?
      @homework = Homework.find(params[:homework_id])
      @homework.destroy
    end

    respond_to do |format|
      format.html { redirect_to homework_history_path, notice: 'Homework was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_homework
    @homework = Homework.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def homework_params
    params.require(:homework).permit(:hw_name, :hw_description, :hw_release_time, :hw_due_time, :hw_test_case_dir)
  end
end
