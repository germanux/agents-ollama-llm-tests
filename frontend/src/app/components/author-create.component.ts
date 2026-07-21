import { Component, DestroyRef, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ApiService, Author } from '../api.service';
import { Router, RouterModule } from '@angular/router';

interface AuthorForm {
  firstName: string;
  lastName: string;
  age: number | null;
}

@Component({
  selector: 'app-author-create',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, RouterModule],
  template: `
    <div class="card">
      <h2>Create Author</h2>
      
      <div *ngIf="successMessage" class="alert alert-success">
        {{ successMessage }}
        <button (click)="closeSuccess()" type="button">&times;</button>
      </div>
      
      <div *ngIf="errorMessage" class="alert alert-error">
        {{ errorMessage }}
        <button (click)="clearError()" type="button">&times;</button>
      </div>
      
      <form [formGroup]="authorForm" (ngSubmit)="onSubmit()">
        <div class="form-group">
          <label for="firstName">First Name</label>
          <input
            id="firstName"
            type="text"
            formControlName="firstName"
            placeholder="Enter first name"
          />
          <div *ngIf="authorForm.controls.firstName.touched && authorForm.controls.firstName.invalid" class="error">
            First name is required
          </div>
        </div>
        
        <div class="form-group">
          <label for="lastName">Last Name</label>
          <input
            id="lastName"
            type="text"
            formControlName="lastName"
            placeholder="Enter last name"
          />
          <div *ngIf="authorForm.controls.lastName.touched && authorForm.controls.lastName.invalid" class="error">
            Last name is required
          </div>
        </div>
        
        <div class="form-group">
          <label for="age">Age</label>
          <input
            id="age"
            type="number"
            formControlName="age"
            placeholder="Enter age"
            min="0"
            max="150"
          />
          <div *ngIf="authorForm.controls.age.touched && authorForm.controls.age.invalid" class="error">
            Please enter a valid age (0-150)
          </div>
        </div>
        
        <button type="submit" [disabled]="authorForm.invalid || loading">Create Author</button>
      </form>
      
      <p style="margin-top: 20px;">
        <a routerLink="/authors">&larr; Back to Authors List</a>
      </p>
    </div>
  `
})
export class AuthorCreateComponent implements OnInit {
  private api = inject(ApiService);
  private router = inject(Router);
  private fb = inject(FormBuilder);
  private destroyRef = inject(DestroyRef);

  authorForm: FormGroup;
  loading = false;
  successMessage: string | null = null;
  errorMessage: string | null = null;

  ngOnInit(): void {
    this.authorForm = this.fb.group({
      firstName: ['', Validators.required],
      lastName: ['', Validators.required],
      age: [null, [Validators.min(0), Validators.max(150)]]
    });
  }

  onSubmit(): void {
    if (this.authorForm.invalid || this.loading) {
      return;
    }

    const payload = this.authorForm.value as Author;

    this.loading = true;
    this.errorMessage = null;

    this.api.createAuthor(payload).subscribe({
      next: () => {
        this.successMessage = 'Author created successfully!';
        setTimeout(() => {
          this.router.navigate(['/authors']);
        }, 1500);
      },
      error: (error) => {
        this.errorMessage = error.message || 'Failed to create author';
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
