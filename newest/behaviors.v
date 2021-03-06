Require Import erasure. 
Require Import Coq.Sets.Ensembles. 
Require Import errorIFF. 
Require Import SpecImpliesNonSpec.
Require Import Divergence.  
Require Import nonspeculativeImpliesSpeculative. 

Inductive specFinalState : Type :=
|Done : trm -> specFinalState
|Diverge : specFinalState 
|Error : specFinalState. 

Inductive waitingOnEmpty : trm -> sHeap -> Prop := 
|waitingOnEmpty_ : forall t E x H, 
         decompose t E (get (fvar x)) -> heap_lookup x H = Some(sempty COMMIT) ->
         waitingOnEmpty t H.

Fixpoint specFinished H (T:pool) :=
  match T with
      |(_, unlocked nil, _, ret M)::Ts => specFinished H Ts
      |(_, unlocked nil, _, M)::Ts => waitingOnEmpty M H /\ specFinished H Ts
      |(_, specStack _ _, _, _)::Ts => specFinished H Ts
      |(_, locked _, _, _)::Ts => specFinished H Ts
      |nil => True
      | _ => False
  end. 

Inductive specRunPar (M:trm) : specFinalState -> Prop :=
|specRunParDone : forall H' T tid s2 N, 
    multistep (Heap.empty ivar_state) 
              (tSingleton ([1], unlocked nil, nil, bind M (lambda (done (bvar 0)))))
              (Some(H', (tUnion T (tSingleton(tid, unlocked nil, s2, done N))))) -> 
    specFinished H' T -> specRunPar M (Done N)
|specRunParError :
   multistep (Heap.empty ivar_state) 
             (tSingleton ([1], unlocked nil, nil, bind M (lambda (done (bvar 0)))))
             None -> specRunPar M Error
|specrunParDiverge : 
   SpecDiverge (Heap.empty ivar_state) 
               (tSingleton([1],unlocked nil,nil,bind M (lambda (done (bvar 0))))) ->
   specRunPar M Diverge. 

Inductive parFinalState : Type :=
|pDone : ptrm -> parFinalState
|pDiverge : parFinalState 
|pError : parFinalState. 

Inductive pWaitingOnEmpty : ptrm -> pHeap -> Prop :=
|pwaitingOnEmpty_ : forall t E x H,
                      pdecompose t E (pget (pfvar x)) -> heap_lookup x H = Some pempty ->
                      pWaitingOnEmpty t H. 

Fixpoint parFinished H (T:pPool) :=
  match T with
    |pret M::Ts => parFinished H Ts
    |t::Ts => pWaitingOnEmpty t H /\ parFinished H Ts
    |nil => True
  end. 

Inductive parRunPar (M:ptrm) : parFinalState -> Prop :=
|parRunParDone : forall H' T N,
                   pmultistep (Heap.empty pivar_state) (pSingle (pbind M (plambda (pdone (pbvar 0)))))
                             (Some(H', pUnion T (pSingle (pdone N)))) -> parFinished H' T -> 
                   parRunPar M (pDone N)
|parRunParError : pmultistep (Heap.empty pivar_state) (pSingle (pbind M (plambda (pdone (pbvar 0)))))
                             None -> parRunPar M pError
|parRunParDiverge : ParDiverge (Heap.empty pivar_state) 
                               (pSingle(pbind M (plambda (pdone (pbvar 0))))) ->
                    parRunPar M pDiverge. 
                               

Inductive specBehavior (M:trm) : (Ensemble specFinalState) := 
|specBehavior_ : forall s, 
                   specRunPar M s -> Ensembles.In specFinalState (specBehavior M) s. 

Inductive parBehavior (M:ptrm) : (Ensemble parFinalState) :=
|parBehavior_ : forall s, parRunPar M s -> Ensembles.In parFinalState (parBehavior M) s. 

Inductive eraseBehaviors (b : Ensemble specFinalState) : Ensemble parFinalState :=
|eraseError : Ensembles.In specFinalState b Error -> 
              Ensembles.In parFinalState (eraseBehaviors b) pError
|eraseDone : forall M, Ensembles.In specFinalState b (Done M) ->
                       Ensembles.In parFinalState (eraseBehaviors b) (pDone (eraseTerm M))
|eraseDiverge : Ensembles.In specFinalState b Diverge -> 
                Ensembles.In parFinalState (eraseBehaviors b) pDiverge.

Theorem raw_eraseCommitEmpty : forall x H,
                             raw_heap_lookup x H = Some(sempty COMMIT) ->
                             raw_heap_lookup x (raw_eraseHeap H) = Some pempty. 
Proof.
  induction H; intros. 
  {inv H. }
  {simpl in *. destruct a. destruct (beq_nat x i) eqn:eq. 
   {inv H0. simpl. rewrite eq. auto. }
   {destruct i0. destruct s. eauto. simpl. rewrite eq; eauto. 
    destruct s. eauto. destruct s0; simpl; rewrite eq; eauto. }
  }
Qed. 

Theorem eraseCommitEmpty : forall x H,
                             heap_lookup x H = Some(sempty COMMIT) ->
                             heap_lookup x (eraseHeap H) = Some pempty. 
Proof.
  intros. destruct H. simpl. eapply raw_eraseCommitEmpty. eauto. 
Qed. 

Theorem waitingOnEmptyEq : forall e H,
                             waitingOnEmpty e H->
                             pWaitingOnEmpty (eraseTerm e) (eraseHeap H). 
Proof.
  intros. inv H0. erewrite <- decomposeErase in H2; eauto. econstructor. 
  simpl in *. eassumption. eapply eraseCommitEmpty; eauto. 
Qed. 

Theorem specFinishedParFinished : forall H T,
                                    specFinished H T -> 
                                    parFinished (eraseHeap H) (erasePool T). 
Proof.
  induction T; intros. 
  {auto. }
  {destruct a. destruct p. destruct p. destruct a. 
   {simpl in *. auto. }
   {destruct l0. simpl in H0. destruct t; try solve[invertHyp; 
    eapply waitingOnEmptyEq in H1; simpl in *; split; auto].
    simpl. eauto. simpl in *. contradiction. }
   {simpl in *. auto. }
  }
Qed. 

Ltac proveWF := econstructor; simpl; erewrite rawHeapsEq; auto; constructor. 

Fixpoint sourceProg t :=
  match t with
      |fvar x => True
      |bvar x => True
      |unit => True
      |pair_ e1 e2 => sourceProg e1 /\ sourceProg e2
      |lambda e => sourceProg e
      |AST.app e1 e2 => sourceProg e1 /\ sourceProg e2
      |ret e => sourceProg e
      |bind e1 e2 => sourceProg e1 /\ sourceProg e2
      |fork e => sourceProg e
      |new => True
      |put e1 e2 => sourceProg e1 /\ sourceProg e2
      |get e => sourceProg e
      |raise e => sourceProg e
      |handle e1 e2 => sourceProg e1 /\ sourceProg e2
      |spec e1 e2 => sourceProg e1 /\ sourceProg e2
      |specRun e1 e2 => False
      |specJoin e1 e2 => False
      |fst e => sourceProg e
      |snd e => sourceProg e
      |done e => sourceProg e
  end. 



Theorem eraseSourceProg : forall M, sourceProg M -> psourceProg (eraseTerm M).
Proof.
  induction M; intros; simpl; auto; 
  try solve[simpl in *; invertHyp; apply IHM1 in H0; apply IHM2 in H1; auto].
Qed. 

Theorem specEraseTerm : forall M, specTerm (eraseTerm M) = M. 
Proof.
  induction M; intros; auto; try solve[ 
  simpl; rewrite IHM1; rewrite IHM2; auto];
  simpl; rewrite IHM; auto. 
Qed.  

Theorem specFinishedComm : forall T1 H T2, specFinished H (tUnion T1 T2) <-> 
                                           (specFinished H T1 /\ specFinished H T2). 
Proof.
  induction T1; intros; split; intros. 
  {simpl in *. auto. }
  {simpl in *. invertHyp. auto. }
  {destruct a. destruct p. destruct p. destruct a. 
   {simpl in *. eapply IHT1; eauto. }
   {destruct l0. simpl in *. 
    destruct t; try solve[invertHyp; eapply IHT1 in H2; invertHyp; eauto].
    eapply IHT1; eauto. contradiction. }
   {simpl in *. eapply IHT1; eauto. }
  }
  {destruct a. destruct p. destruct p. destruct a. 
   {simpl in *. eapply IHT1; eauto. }
   {destruct l0. simpl in *. 
    destruct t; try solve[invertHyp; split; eauto; eapply IHT1; eauto]. 
    eapply IHT1; eauto. simpl in *. invertHyp; auto. }
   {simpl in *. eapply IHT1; eauto. }
  }
Qed. 

Theorem gatherFinished : forall t T H, 
                           gather t T -> specFinished H T. 
Proof.
  intros. induction H0; try solve[constructor]; eauto; 
          try solve[rewrite specFinishedComm; eauto]. 
  {repeat rewrite specFinishedComm. simpl. eauto. }
Qed. 


Theorem parWaitingOneEmpty : forall H t' H' t, pWaitingOnEmpty t H -> specHeap H H' ->
                                         t' = specTerm t -> waitingOnEmpty t' H'. 
Proof.
  intros. inv H0. apply decomposeSpec in H4. econstructor. simpl in *. eauto. 
  eapply specHeapLookupEmpty; eauto. 
Qed. 

Theorem parFinishedSpecFinished : forall H H' T T',
                                    specHeap H H' -> speculate T T' ->
                                    parFinished H T -> specFinished H' T'. 
Proof.
  induction T; intros. 
  {inv H2. inv H1. simpl. auto. }
  {inv H1. rewrite specFinishedComm. split.
   eapply gatherFinished; eauto. simpl in *.  
   destruct a; simpl; eauto; invertHyp; split; eauto; eapply parWaitingOneEmpty; eauto. }
Qed. 

Theorem SpecEqPar : forall M, 
                      sourceProg M -> 
                      eraseBehaviors (specBehavior M) = parBehavior (eraseTerm M).
Proof.
  intros. eqSets. 
  {inv H0. 
   {inv H1. constructor. inv H0. constructor. eapply specErrorParErrorStar in H1. 
    simpl in *. unfold Heap.empty. erewrite rawHeapsEq. eauto. auto. proveWF. }
   {inv H1. inv H0. copy H2. eapply specImpliesNonSpecMulti in H2. invertHyp. 
    constructor. rewrite eraseUnionComm in H1. simpl in H1. econstructor. 
    unfold Heap.empty. erewrite rawHeapsEq. eassumption. auto. 
    apply specFinishedParFinished; auto. proveWF. }
   {inv H1. inv H0. constructor. eapply SpecDivergeParDiverge in H1. constructor. 
    unfold Heap.empty. erewrite rawHeapsEq. simpl in *. eassumption. auto. proveWF. }
  }
  {inv H0. inv H1. 
   {existTac N. constructor. constructor. apply eraseSourceProg in H. 
    gatherTac (eraseTerm M). copy H. eapply gatherSourceProg in H; eauto. copy H0. 
    eapply nonspecImpliesSpecStar in H0;[idtac|idtac|idtac|constructor|constructor].  
    Focus 2. constructor. constructor. constructor. eauto. repeat constructor. 
    Focus 2. simpl. repeat split; auto. invertHyp. simpl in H0. 
    apply specUnionComm in H. invertHyp. inv H. inv H9. inv H11. apply pmultistepWF in H4.
    invertHyp. apply poolWFComm in H. simpl in *. invertHyp.
    eapply gatherSourceProg in H; eauto. subst. simpl in H0. econstructor. 
    repeat rewrite specEraseTerm in H0. unfold Heap.empty. 
    erewrite (rawHeapsEq ivar_state). eassumption. auto.
    eapply parFinishedSpecFinished; eauto. simpl. auto. constructor. }
   {assert(specTerm (eraseTerm M) = M). rewrite specEraseTerm. auto. 
    constructor. constructor. constructor. eapply ParErrorSpecErrorStar in H0. 
    eauto. unfold Heap.empty. erewrite (rawHeapsEq ivar_state); auto. constructor. 
    constructor. constructor. apply eraseSourceProg in H. constructor. auto. 
    repeat constructor. constructor. rewrite <- union_empty_l. rewrite <- H1. 
    replace (bind(specTerm(eraseTerm M)) (lambda(done(bvar 0)))) with 
    (specTerm(pbind (eraseTerm M) (plambda(pdone (pbvar 0))))); auto. rewrite specEraseTerm. 
    constructor. constructor. rewrite <- union_empty_l. constructor. apply eraseSourceProg in H. 
    gatherTac (eraseTerm M). copy H3. eapply gatherSourceProg in H3; eauto. rewrite H3 in H2. 
    auto. repeat constructor. }
   {assert(specTerm (eraseTerm M) = M). rewrite specEraseTerm. auto. 
    constructor. constructor. constructor. eapply ParDivergeSpecDiverge in H0. 
    eauto. unfold Heap.empty. erewrite (rawHeapsEq ivar_state); auto. constructor. 
    rewrite <- union_empty_l. rewrite <- H1. 
    replace (bind(specTerm(eraseTerm M)) (lambda(done(bvar 0)))) with 
    (specTerm(pbind (eraseTerm M) (plambda(pdone (pbvar 0))))); auto. rewrite specEraseTerm. 
    constructor. constructor. rewrite <- union_empty_l. constructor. apply eraseSourceProg in H. 
    gatherTac (eraseTerm M). copy H3. eapply gatherSourceProg in H3; eauto. rewrite H3 in H2. 
    auto. repeat constructor. constructor. simpl. apply eraseSourceProg in H. auto. }
  }
  Grab Existential Variables. constructor. constructor. constructor. 
Qed. 


(*Assumed based on previous work*)
Axiom ParDet : forall M M' M'', parRunPar M M' -> parRunPar M M'' -> M' = M''. 

Ltac SpecDetTac := 
  match goal with
      |H:_ |- _ => eapply specImpliesNonSpecMulti in H
      |H:_ |- _ => eapply specErrorParErrorStar in H
      |H:_ |- _ => apply SpecDivergeParDiverge in H
  end. 

Ltac runParDoneTac M N :=
  try(rewrite eraseUnionComm in *); 
  assert(parRunPar (eraseTerm M) (pDone (eraseTerm N))) by 
    (econstructor;[simpl in *; unfold Heap.empty; erewrite rawHeapsEq; eauto|
                   eapply specFinishedParFinished; eauto]).

Ltac runParErrorTac M :=
  assert(parRunPar (eraseTerm M) pError) by
    (constructor; simpl in *; unfold Heap.empty; erewrite rawHeapsEq; eauto). 

Ltac runParDivergeTac M :=
  assert(parRunPar (eraseTerm M) pDiverge) by
    (constructor; simpl in *; unfold Heap.empty; erewrite rawHeapsEq; eauto). 

Ltac resultsDisagree := 
  match goal with
      |H:parRunPar ?M ?N,H':parRunPar ?M ?N' |- _ => eapply ParDet in H; eauto; solveByInv
  end. 

Theorem SpecDet : forall M M' M'', specRunPar M M' -> specRunPar M M'' -> M' = M''.
Proof.
  intros. inv H; inv H0; try (SpecDetTac;[SpecDetTac;[idtac|proveWF]|proveWF]); auto. 
  {invertHyp. runParDoneTac M N. runParDoneTac M N0. eapply ParDet in H; eauto. 
   inv H. apply eraseTermUnique in H6. subst. auto. }
  {invertHyp. runParDoneTac M N. runParErrorTac M. resultsDisagree. }
  {invertHyp. runParDoneTac M N. runParDivergeTac M. resultsDisagree. }
  {invertHyp. runParDoneTac M N. runParErrorTac M. resultsDisagree. }
  {runParErrorTac M. runParDivergeTac M. resultsDisagree. }
  {invertHyp. runParDoneTac M N. runParDivergeTac M. resultsDisagree. }
  {runParDivergeTac M. runParErrorTac M. resultsDisagree. }
Qed. 









