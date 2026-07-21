import { Routes } from '@angular/router';
import { AuthorListComponent } from './components/author-list.component';
import { AuthorCreateComponent } from './components/author-create.component';
import { BookListComponent } from './components/book-list.component';
import { BookCreateComponent } from './components/book-create.component';
import { AuthorDetailComponent } from './components/author-detail.component';

export const routes: Routes = [
  {
    path: '',
    redirectTo: '/authors',
    pathMatch: 'full'
  },
  {
    path: 'authors',
    component: AuthorListComponent
  },
  {
    path: 'authors/create',
    component: AuthorCreateComponent
  },
  {
    path: 'books',
    component: BookListComponent
  },
  {
    path: 'books/create',
    component: BookCreateComponent
  },
  {
    path: 'authors/:id',
    component: AuthorDetailComponent
  }
];
