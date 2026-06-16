module ApplicationHelper
  # Renders a styled button-link. style: :primary | :secondary | :danger | :link
  def button_link(text, path, style: :primary, **html_options)
    css_class = ["btn", "btn-#{style}"]
    css_class << html_options.delete(:class) if html_options[:class]
    link_to text, path, html_options.merge(class: css_class.join(" "))
  end

  # Renders a styled destructive button-link with a Turbo confirm dialog.
  def delete_link(text, path, confirm: "Are you sure?", **html_options)
    button_link text, path, style: :danger, data: { turbo_method: :delete, turbo_confirm: confirm }, **html_options
  end
end
