# Sombrero routes

| View                        | API                     |
|-----------------------------|-------------------------|
| GET /                       | n/a                     |
| GET /images/photos/*        | (same as left)          |
| GET /images/samples/*       | (same as left)          |
| GET /images/thumbs/*        | (same as left)          |
| GET /clip/new               | n/a                     |
| POST /clip                  | POST /api/clip          |
| GET /post/new               | n/a                     |
| POST /post                  | POST /api/post          |
| GET /recent/:page           | GET /api/posts          |
| GET /list                   | n/a                     |
| GET /list/:page             | n/a                     |
| GET /wallpapers/:size       | n/a                     |
| GET /wallpapers/:size/:page | n/a                     |
| n/a                         | GET /api/post/:id       |
| POST /post/:id.edit         | n/a                     |
| PUT /post/:id               | n/a                     |
| GET /post/:id.delete        | n/a                     |
| n/a                         | GET /api/photos         |
| GET /photo/:id              | GET /api/photo/:id      |
| GET /photo/md5/:md5         | GET /api/photo/md5/:md5 |
| GET /photo/sha256/:sha256   | n/a                     |
| GET /photo/name/:name       | n/a                     |
| POST /photo/:id.edit        | n/a                     |
| PUT /photo/:id              | n/a                     |
| POST /photo/update-tags     | n/a                     |
| GET /photo/:id.delete       | n/a                     |
| GET /tags/:page             | n/a                     |
| GET /tags/edit/:id          | n/a                     |
| PUT /tags/edit/:id          | n/a                     |
| GET /tagtypes/new           | n/a                     |
| POST /tagtypes/new          | n/a                     |
| GET /tagtypes/:page         | n/a                     |
| GET /tagtypes/edit/:id      | n/a                     |
| PUT /tagtypes/edit/:id      | n/a                     |
| n/a                         | GET /api/statistics









