; RUN: if [ %llvmver -lt 16 ]; then %opt < %s %loadEnzyme -enzyme-preopt=false -enzyme -mem2reg -instsimplify -loop-deletion -correlated-propagation -adce -simplifycfg -S | FileCheck %s; fi
; RUN: %opt < %s %newLoadEnzyme -enzyme-preopt=false -passes="enzyme,function(mem2reg,instsimplify,loop(loop-deletion),correlated-propagation,adce,%simplifycfg)" -S | FileCheck %s

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local double @sum(double* nocapture readonly %x, i64 %n) #0 {
entry:
  br label %for.body

for.cond.cleanup:                                 ; preds = %for.body
  ret double %add

for.body:                                         ; preds = %entry, %for.body
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next, %for.body ]
  %total.07 = phi double [ 0.000000e+00, %entry ], [ %add, %for.body ]
  %arrayidx = getelementptr inbounds double, double* %x, i64 %indvars.iv
  %0 = load double, double* %arrayidx, align 8
  %add = fadd fast double %0, %total.07
  %indvars.iv.next = add nuw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv, %n
  br i1 %exitcond, label %for.cond.cleanup, label %for.body
}

; Function Attrs: nounwind uwtable
define dso_local void @dsum(double* %x, double* %xp, i64 %n) local_unnamed_addr #1 {
entry:
  %0 = tail call double (double (double*, i64)*, ...) @__enzyme_autodiff(double (double*, i64)* nonnull @sum, double* %x, double* %xp, i64 %n)
  ret void
}

; Function Attrs: nounwind
declare double @__enzyme_autodiff(double (double*, i64)*, ...) #2

attributes #0 = { norecurse nounwind readonly uwtable }
attributes #1 = { nounwind uwtable }
attributes #2 = { nounwind }


; CHECK: define internal void @diffesum(double* nocapture readonly %x, double* nocapture %"x'", i64 %n, double %differeturn)
; CHECK-NEXT: entry:
; CHECK-NEXT:   br label %invertfor.body

; CHECK:  invertentry:
; CHECK-NEXT:  ret void

; CHECK: invertfor.body:

; CHECK-NEXT:   %[[antiiv:.+]] = phi i64 [ %n, %entry ], [ %[[antiivnext:.+]], %incinvertfor.body ]
; CHECK-NEXT:   %[[arrayidxipgi:.+]] = getelementptr inbounds double, double* %"x'", i64 %[[antiiv]]
; CHECK-NEXT:   %[[load:.+]] = load double, double* %[[arrayidxipgi]]
; CHECK-NEXT:   %[[tostore:.+]] = fadd fast double %[[load]], %differeturn
; CHECK-NEXT:   store double %[[tostore]], double* %[[arrayidxipgi]]
; CHECK-NEXT:   %[[cmp:.+]] = icmp eq i64 %[[antiiv]], 0
; CHECK-NEXT:   br i1 %[[cmp]], label %invertentry, label %incinvertfor.body

; CHECK: incinvertfor.body:
; CHECK-NEXT:   %[[antiivnext]] = add nsw i64 %[[antiiv]], -1
; CHECK-NEXT:   br label %invertfor.body
