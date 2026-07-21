import { Component, DestroyRef, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule, ActivatedRoute,NavigationEnd } from '@angular/router';
import { PageTitleService } from './page-title.service';
import { AppService } from './app.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <header>
      <h1>Library Management System</h1>
    </header>
    
    <nav>
      <a routerLink="/authors" routerLinkActive="active">Authors</a>
      <a routerLink="/books" routerLinkActive="active">Books</a>
    </nav>
    
    <main class="container main-content">
      <router-outlet></router-outlet>
    </main>
  `
})
export class AppComponent implements OnInit {
  private router = inject(Router);
  private pageTitleService = inject(PageTitleService);

  ngOnInit(): void {
    this.router.events.subscribe((event) => {
      if (event instanceof NavigationEnd) {
        const url = event.urlAfterRedirects;
        
        if (url.includes('/authors/create')) {
          this.pageTitleService.setTitle('Create Author');
        } else if (url.includes('/books')) {
          this.pageTitleService.setTitle('Books');
        } else if (url.includes('/authors')) {
          this.pageTitleService.setTitle('Authors');
        } else {
          this.pageTitleService.setTitle('Home');
        }
      }
    });
  }
}
