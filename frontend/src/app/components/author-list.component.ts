import { Component, DestroyRef, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { ApiService, AuthorDto } from '../api.service';
import { AppService } from './app.service';

@Component({
  selector: 'app-author-list',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="card">
      <h2>Authors</h2>
      
      <div *ngIf="successMessage" class="alert alert-success">
        {{ successMessage }}
        <button (click)="closeSuccess()" type="button">&times;</button>
      </div>
      
      <div *ngIf="errorMessage" class="alert alert-error">
        {{ errorMessage }}
        <button (click)="clearError()" type="button">&times;</button>
      </div>
      
      <div class="author-controls">
        <a routerLink="/authors/create">+ Add New Author</a>
      </div>
      
      <div *ngIf="loading" class="loading">Loading authors...</div>
      
      <div *ngIf="!loading && authors.length === 0" class="no-data">
        No authors found.
      </div>
      
      <div *ngIf="!loading && authors.length > 0" class="authors-grid">
        <div 
          *ngFor="let author of authors" 
          (click)="selectAuthor(author)"
          class="author-item"
        >
          <h3>{{ author.firstName }} {{ author.lastName }}</h3>
          <p>Age: {{ author.age }}</p>
        </div>
      </div>
    </div>
  `
})
export class AuthorListComponent implements OnInit {
  private api = inject(ApiService);
  private appService = inject(AppService);
  private destroyRef = inject(DestroyRef);

  authors: AuthorDto[] = [];
  loading = false;
  successMessage: string | null = null;
  errorMessage: string | null = null;

  ngOnInit(): void {
    this.loadAuthors();
    
    this.appService.selectedAuthor$
      .pipe(this.destroyRef)
      .subscribe({
        next: (author) => {
          if (author && !this.loading) {
            this.selectAuthor(author);
          }
        }
      });
  }

  loadAuthors(): void {
    this.loading = true;
    this.errorMessage = null;
    
    this.api.getAuthors().subscribe({
      next: (data) => {
        this.authors = data;
        this.loading = false;
      },
      error: (error) => {
        this.errorMessage = error.message || 'Failed to load authors';
        this.loading = false;
      }
    });
  }

  selectAuthor(author: AuthorDto): void {
    this.appService.setSelectedAuthor(author);
  }

  closeSuccess(): void {
    this.successMessage = null;
  }

  clearError(): void {
    this.errorMessage = null;
  }

  trackByAuthorId(index: number, author: AuthorDto): number | undefined {
    return author.id ?? index;
  }
}
