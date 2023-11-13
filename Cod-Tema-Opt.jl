using JuMP
using HiGHS

Departamente = ["Frontend", "Backend"]
Frontend=[2530, 3018.75, 2300, 3453.45, 4140, 2530, 4462.92, 2887.5, 3795, 4638.8] #salariile cerute inițial de candidații ce au aplicat pentru departamentul 
                                                                                    #de Frontend
Backend=[4025, 4158, 3465, 5578.65, 3300, 3984.75, 4491.9, 3696, 2800, 4427.5] #salariile cerute intial de candidații ce au aplicat pentru departamentul 
                                                                                #de Backend
Experience=[5 3 7 1 4 2 3 1 6 4;
            5 3 7 1 3 4 2 4 3 6] #matricea cu anii de experiența a fiecarui candidat(pe linia 1 a celor de la Frontend și pe linia 2 a celor la Backend)

Women=[2, 3, 6, 7, 8, 10] #vectorul pozitiilor din lista a candidatilor de sex feminin (din motive de simplitate e acelasi la ambele departamente)
W=length(Women) #lungimea vectorului Women

Master=[2, 4, 5, 8,10] #vectorul pozitiilor din listă a candidaților cu diplomă de master (din motive de simplitate e acelasi la ambele departamente)
M=length(Master) #lungimea vectorului Master

Apt_R=[1, 4 ,6, 7, 8, 9] #vectorul pozitiilor din listă a candidților pentru Frontend ce dețin aptitudinea R 
A_r=length(Apt_R) #lungimea vectorului Apt_R

Apt_L_f=[1, 2, 4, 5, 6, 7, 9, 10] #vectorul pozitiilor din listă a candidților pentru Frontend ce dețin aptitudinea L
A_l_f=length(Apt_L_f) #lungimea vectorului Apt_L_f

Apt_C=[2, 4, 7, 8, 10] #vectorul pozitiilor din listă a candidților pentru Frontend ce dețin aptitudinea C
A_c=length(Apt_C) #lungimea vectorului Apt_C

Apt_F=[2, 4, 7] #vectorul pozitiilor din listă a candidților pentru Backend ce dețin aptitudinea F 
A_f=length(Apt_F) #lungimea vectorului Apt_F

Apt_L_b=[1, 4, 6, 7, 10] #vectorul pozitiilor din listă a candidților pentru Backend ce dețin aptitudinea L
A_l_b=length(Apt_L_b) #lungimea vectorului Apt_L_b

C=length(Frontend)    #C este numarul de aplicanti pentru fiecare department 
L=length(Departamente)    #L este numarul de departamente

#Cream matricea cu salariile finale pentru fiecare departament
Employee = Array{Float64}(undef, 2, C)
for i in 1:C
    Employee[1,i]=Frontend[i]
    Employee[2,i]=Backend[i]
end

#Afisam matricea
println("Matricea salariilor finale solicitate este: ")
println(Employee)
 
#Realizam modelul
IC = Model(HiGHS.Optimizer)

#Alegem variabilele integrale si pozitive
@variable(IC, x[l=1:L, c=1:C], Bin)

#Scriem functia
@objective(IC, Max, sum(Employee[l,c] * x[l,c] for l in 1:L, c in 1:C))

#Scriem Restrictiile
@constraint(IC, sum(Employee[l,c] * x[l,c] for l in 1:L, c in 1:C) <= 25000) #Ne asiguram ca salariul tuturor angajatilor nu depaseste 21000
@constraint(IC, sum(x[1,c] for c in 1:C) == 3) #Ne asiguram ca angajam 3 Frontend Developeri
@constraint(IC, sum(x[2,c] for c in 1:C) == 3) #Ne asiguram ca angajam 3 Backend Developeri
@constraint(IC, sum(Experience[1,c] * x[1,c] for c in 1:C) >= 6) #Experienta pentru Frontend
@constraint(IC, sum(Experience[2,c] * x[2,c] for c in 1:C) >= 9) #Experienta pentru Backend
@constraint(IC, sum(Experience[l,c] * x[l,c] for l in 1:L, c in 1:C) >= 18) #Experienta combinata
@constraint(IC, sum(x[1,Women[w]] for w in 1:W) >= 1) #Macar o femeie e angajata ca Frontend Dev 
@constraint(IC, sum(x[2,Women[w]] for w in 1:W) >= 1) #Macar o femeie e angajata ca Backend Dev
@constraint(IC, sum(x[1,Master[m]] for m in 1:M) >= 1) #Macar o persoana cu diploma de master e angajata ca Frontend Dev
@constraint(IC, sum(x[2,Master[m]] for m in 1:M) >= 1) #Macar o persoana cu diploma de master e angajata ca Backend Dev
@constraint(IC, sum(x[1,Apt_R[i]] for i in 1:A_r) >= 1) #Macar o persoana are aptitudinea R ca Frontend Dev
@constraint(IC, sum(x[1,Apt_L_f[i]] for i in 1:A_l_f) >= 1) #Macar o persoana are aptitudinea L ca Frontend Dev
@constraint(IC, sum(x[1,Apt_C[i]] for i in 1:A_c) >= 1) #Măcar o persoana are aptitudinea C ca Frontend Dev
@constraint(IC, sum(x[2,Apt_F[i]] for i in 1:A_f) >= 1) #Macar o persoana are aptitudinea F ca Backend Dev
@constraint(IC, sum(x[2,Apt_L_b[i]] for i in 1:A_l_b) >= 1) #Macar o persoana are aptitudinea L ca Backend Dev
@constraint(IC, [l=1:L, c=1:C], x[l,c] <= 1) #Ne asiguram ca rezultatul sa fie cat mai aproape de realitate astfel incat x va fi 1 daca candidatul e angajat,
                                             # respectiv 0 daca NU este angajat
#Optimizam modelul
optimize!(IC)

println("Status: $(termination_status(IC))")
if termination_status(IC) == MOI.OPTIMAL
    println("Valoarea functiei obiectiv: $(objective_value(IC))")

    #Afisam matricea x ca sa ne dam seama daca au fost facute bine calculele
    println("Matricea x este: ")
    for l in 1:L
        for c in 1:C
            print("| $(value(x[l,c])) |")
        end
        println("")
    end

    #Punem niste instructiuni de afisare mai usor de vazut si inteles
    for l in 1:L
    println("Candidații angajați pentru departamentul de $(Departamente[l]): ")
        for c in 1:C
            if value(x[l,c]) >= 0.9999
            println("Candidatul nr. $(c) a fost angajat.")
            end
        end
    end
else
    println("Nu exista solutii disponibile")
end