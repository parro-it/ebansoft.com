{{ useLayout("home.njk") }}
{{ title("EbanSoft blog | home") }}
{{ subtitle("Thoughts on Javascript and C development.") }}

__Latest articles__

{% for path, post in registry.entries %}
## [{{ post.title }}]({{ path }})

![post header picture](https://source.unsplash.com/random/800x300)

{{ post.subtitle }}

{% endfor %}


