import { Component, DestroyRef, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { ApiService, AuthorDto, BookCreateDto } from '../api.service';

@Component({
  selector: 'app-book-create',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, RouterModule],
  template: `
    <div class="card">
      <h2>Create Book</h2>
      
      <div *ngIf="successMessage" class="alert alert-success">
        {{ successMessage }}
        <button (click)="closeSuccess()" type="button">&times;</button>
      </div>
      
      <div *ngIf="errorMessage" class="alert alert-error">
        {{ errorMessage }}
        <button (click)="clearError()" type="button">&times;</button>
      </div>
      
      <form [formGroup]="bookForm" (ngSubmit)="onSubmit()">
        <div class="form-group">
          <label for="title">Title</label>
          <input
            id="title"
            type="text"
            formControlName="title"
            placeholder="Enter book title"
          />
          <div *ngIf="bookForm.controls['title'].touched && bookForm.controls['title'].invalid" class="error">
            Title is required
          </div>
        </div>
        
        <div class="form-group">
          <label for="description">Description</label>
          <textarea
            id="description"
            formControlName="description"
            placeholder="Enter description"
            rows="3"
          ></textarea>
        </div>
        
        <div class="form-group">
          <label>Authors</label>
          
          <div *ngIf="authors.length === 0" class="no-data">
            No authors available. Please add an author first.
          </div>
          
          <div *ngFor="let author of authors" class="checkbox-item">
            <input
              type="checkbox"
              [id]="'author_' + author.id"
              [value]="author.id"
              [checked]="selectedAuthorIds.includes(author.id!)"
              (change)="toggleAuthorSelection(author.id!, $event)"
            />
            <label [for]="'author_' + author.id">{{ author.firstName }} {{ author.lastName }}</label>
          </div>
          
          <div *ngIf="bookForm.controls['authorIds'].touched && bookForm.controls['authorIds'].invalid" class="error">
            Please select at least one author
          </div>
        </div>
        
        <button type="submit" [disabled]="bookForm.invalid || loading">Create Book</button>
      </form>
      
      <p style="margin-top: 20px;">
        <a routerLink="/books">&larr; Back to Books List</a>
      </p>
    </div>
  `
})
export class BookCreateComponent implements OnInit {
  private api = inject(ApiService);
  private router = inject(Router);
  private fb = inject(FormBuilder);
  private destroyRef = inject(DestroyRef);

  bookForm!: FormGroup;
  loading = false;
  successMessage: string | null = null;
  errorMessage: string | null = null;
  
  authors: AuthorDto[] = [];
  selectedAuthorIds: number[] = [];

  ngOnInit(): void {
    this.bookForm = this.fb.group({
      title: ['', Validators.required],
      description: [''],
      authorIds: [[], Validators.required]
    });

    this.loadAuthors();
  }

  loadAuthors(): void {
    this.api.getAuthors().subscribe({
      next: (data) => {
        this.authors = data;
      }
    });
  }

  toggleAuthorSelection(id: number, event: Event): void {
    const checkbox = event.target as HTMLInputElement;
    
    if (checkbox.checked) {
      this.selectedAuthorIds.push(id);
    } else {
      this.selectedAuthorIds = this.selectedAuthorIds.filter(authorId => authorId !== id);
    }
    
    this.bookForm.controls['authorIds'].setValue(this.selectedAuthorIds);
    this.bookForm.controls['authorIds'].markAsTouched();
  }

  onSubmit(): void {
    if (this.bookForm.invalid || this.loading) {
      return;
    }

    const dto: BookCreateDto = {
      title: this.bookForm.controls['title'].value,
      description: this.bookForm.controls['description'].value,
      authorIds: this.bookForm.controls['authorIds'].value
    };

    if (!dto.authorIds || dto.authorIds.length === 0) {
      this.errorMessage = 'Please select at least one author';
      return;
    }

    this.loading = true;
    this.errorMessage = null;

    this.api.createBook(dto).subscribe({
      next: () => {
        this.successMessage = 'Book created successfully!';
        setTimeout(() => {
          this.router.navigate(['/books']);
        }, 1500);
      },
      error: (error) => {
        this.errorMessage = error.message || 'Failed to create book';
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
