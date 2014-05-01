Ministry Centered Technologies
==============================

## Developer Blog

[Jekyll](http://jekyllrb.com) powers this blog.

Getting set up.

1. Clone this repo's `gh-pages` branch. `git clone https://github.com/ministrycentered/developers.git -b gh-pages`
2. If you're going to work on the blog itself run `bundle install`
3. To build the site locally `jekyll serve` or `jekyll serve --watch` to live reload your code.

Creating a new post.  

1. Create a new branch.
2. Run `rake post:new["My Post Title"]`
3. Write
4. Push to GitHub
5. Create a pull request into the `gh-pages` branch of this repo.
6. When your pull request is merged Github pages will rebuild the site and your new post will be live.

#### The Post Format

Posts are written in [Markdown](https://daringfireball.net/projects/markdown/).

Each post file should contain a [YAML Front-matter](http://jekyllrb.com/docs/frontmatter/) header.  Using `rake post:new` will pre-fill some values for you.

- `layout` - The layout to use when building the post page.
- `title` - The tile for your post.
- `date` - The date of the post.

There are some optional values you can set.

- `team` - The team this should be categorized under. `devops | mobile | web`
- `author` - Your name
- `header` - An absolute path to an image to use as a header on post pages. [example](http://developers.planningcenteronline.com/2014/05/01/core-data-at-planning-center.html)

The post file can be found in `_posts/`.  The file name should be formatted as `<year>-<month>-<day>-<title>.md` with the title lowercased and words `-` delimited.


***

#### Preferences

Your preferences are stored on your local machine in `.defaults/prefs.json`.

Most preferences have a rake task for setting them.

- Editor

Your preferred markdown editor.  [Mou](http://mouapp.com) is a pretty good one.

```
rake prefs:editor["Mou"]
```

The name of the app should be the same that would open by running `open -a <name> ./file.md`
