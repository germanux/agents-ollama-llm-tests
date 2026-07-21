import { Component, DestroyRef, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { ApiService, Book } from '../api.service';
import { AppService } from './app.service';

@Component({
  selector: 'app-author-detail',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="card">
      <h2 *ngIf="author">Author: {{ author.firstName }} {{ author.lastName }}</h2>
      
      <p *ngIf="author" style="margin-bottom: 20px;">
        Age: {{ author.age }}
      </p>
      
      <div *ngIf="successMessage" class="alert alert-success">
        {{ successMessage }}
        <button (click)="closeSuccess()" type="button">&times;</button>
      </div>
      
      <div *ngIf="errorMessage" class="alert alert-error">
        {{ errorMessage }}
        <button (click)="clearError()" type="button">&times;</button>
      </div>
      
      <h3>Books by this author</h3>
      
      <div *ngIf="loading" class="loading">Loading books...</div>
      
      <div *ngIf="!loading && books.length === 0" class="no-data">
        No books found for this author.
      </div>
      
      <div *ngIf="!loading && books.length > 0" class="books-grid">
        <div 
          *ngFor="let book of books" 
          class="book-item"
        >
          <h3>{{ book.title }}</h3>
        </div>
      </div>
      
      <p style="margin-top: 20px;">
        <a routerLink="/authors">&larr; Back to Authors</a>
      </p>
    </div>
  `
})
export class AuthorDetailComponent implements OnInit {
  private api = inject(ApiService);
  private appService = inject(AppService);
  private destroyRef = inject(DestroyRef);

  author: any = null;
  books: Book[] = [];
  loading = false;
  successMessage: string | null = null;
  errorMessage: string | null = null;

  ngOnInit(): void {
    this.appService.selectedAuthor$
      .pipe(this.destroyRef)
      .subscribe({
        next: (author) => {
          if (author) {
            this.author = author;
            this.loadBooksByAuthor(author.id!);
          }
        }
      });
  }

  loadBooksByAuthor(authorId: number): void {
    if (!authorId) return;

    this.loading = true;
    this.errorMessage = null;

    this.api.getBooksByAuthorId(authorId).subscribe({
      next: (data) => {
        this.books = data;
        this.loading = false;
      },
      error: (error) => {
        this.errorMessage = error.message || 'Failed to load books';
        this.loading = false;
      }
    });
  }

  closeSuccess(): void {
    this.successMessage = null;
  }

  clearError(): void {
    this.errorMessage = null;
  }
}
