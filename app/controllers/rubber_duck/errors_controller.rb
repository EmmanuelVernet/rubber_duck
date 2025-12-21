module RubberDuck
  class ErrorsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:analyze]

    def analyze
      unless Rails.env.development?
        return render json: { error: "Only available in development" }, status: :forbidden
      end
      result = AiService.analyze_error(
        exception_message: params[:exception],
        backtrace: params[:backtrace],
        logs: params[:logs]
      )
      render json: result
    end

  end
end
