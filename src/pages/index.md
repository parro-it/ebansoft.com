

{{ useLayout("../layouts/home.njk") }}
{{ title("EbanSoft blog | home") }}
{{ subtitle("Thoughts on Javascript and C development.") }}

__Latest articles__
{% for path, post in registry.entries %}
{% if ('posts' in post.categories and not post.draft) %}

## [{{ post.title }}]({{ post.url }})
<time datetime="{{ post.published }}">{{ post.publishedFormatted }}</time>

![{{ post.headingCaption }}]({{ post.headingFigure }})

{{ post.subtitle }}


{% endif %}
{% endfor %}


