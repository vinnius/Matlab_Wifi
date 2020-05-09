clear; clc; close all;

% ------------------------------------------------------------------
%  Área de Cobertura (em pixels)
% -----------------------------------------------------------------

area_width=1000;
area_height=1000;
step_grid=100;   % Passo de simulação em pixels


% Ajuste de escala da area de cobertura
a=1:step_grid:area_width;     area_width=a(end);
a=1:step_grid:area_height;   area_height=a(end);

% ------------------------------------------------------------------
%  Paredes
% -----------------------------------------------------------------
% (Referencial no canto superior esquerdo da imagem)
% x_inicial  y_inicial  x_final  y_final
          
wall_v = [ 100 100 100 900 ];

wall_h = [ 1 500 900 500;
           1 501 900 501 ];
          
          
[l,c]=size(wall_v);
wall_matrix_final=zeros(area_height,area_width);
   

 
for i=1:l

wall_matrix=compute_path_matrix(area_width,area_height,wall_v(i,1),wall_v(i,2),wall_v(i,3),wall_v(i,4));
wall_matrix_final=wall_matrix_final+wall_matrix;
   
end
   
% ------------------------------------------------
% Plota Planta Baixa (1)
% ------------------------------------------------

%figure(1)
%imshow(wall_matrix_final)

[l,c]=size(wall_h);



for i=1:l

wall_matrix=compute_path_matrix(area_width,area_height,wall_h(i,1),wall_h(i,2),wall_h(i,3),wall_h(i,4));
wall_matrix_final=wall_matrix_final+wall_matrix;
   
end



% ------------------------------------------------
% Plota Planta Baixa (2)
% ------------------------------------------------

figure(1)
imshow(wall_matrix_final)



% -----------------------------------------------------------------------------
% Teste das Obstruções
% -----------------------------------------------------------------------------

% Posição do Access Point (AP)
x_ap=124;           y_ap=899;       
% O referencial está no canto superior esquerdo da imagem
% (apesar do referencial dos eixos do gráfico estarem no canto inferior esquerdo)

% Posição do Cliente 
x_client=1;    y_client=1;

signal_path_matrix=compute_path_matrix(area_width,area_height,x_ap,y_ap,x_client,y_client);

% figure(2);
% imshow(wall_matrix_final+signal_path_matrix);


number_of_obstructions=compute_wall_obstructions(area_width,area_height,wall_v,wall_h,signal_path_matrix);
number_of_obstructions;

%pause
% -----------------------------------------------------------------------------   
   
% Coordenadas do Access Point (AP) - Exemplo   
%x_ap=85;           y_ap=340;  
%x_ap=1;           y_ap=1;  

% ------------------------------------------------------------------------------------
% Dados do AP
% ------------------------------------------------------------------------------------
f=2.412e9;           % Frequência do Canal 1 do WiFi em 2.4GHz
Pt_dBm=15;           % Potência de Transmissão em dBm
Gt=0;                % Ganho da Antena Transmissora (dBi)
Gr=0;                % Ganho da Antena Receptora (dBi)
n=2.0;               % Expoente de Perda de Percurso do Log-Distance
d0=1;                % Distância de Referencia (1m)
sigma2=10;           % Variância do Sombreamento (dB) - Shadowing

c=3e8;               % Velocidade Aproximada da Luz
lambda=c/f;          % Comprimento de Onda

% Perda de Percurso na Distância de Refêrencia
PL_d0_dB=10*log10((4*pi*d0/lambda)^2);  

y=1:area_height;
x=1:area_width;

Pr_dBm=zeros(length(y),length(x));
Taxa=zeros(length(y),length(x)); % <--------------------- Matriz Taxa

% Número de Pontos Calculados no Grid 
total_steps=length([1:step_grid:length(x)])*length([1:step_grid:length(y)]);
step=1;




for i=1:step_grid:length(y)
    for j=1:step_grid:length(x)
        
        % Display dos Passos Simulados
        % [step total_steps]
        step=step+1;
        
% -----------------------------------------------------------------------------------------------------------------------------
% -----------------------------------------------------------------------------------------------------------------------------
         % Calcula Distancia em Pixels
         d=sqrt((x(j)-x_ap)^2+(y(i)-y_ap)^2);
        
         % Calcula Distancia em Metros (8.6 pixels/metro) - Ajust�vel/Configur�vel
         d=d./10;
        
         % Efeito de Sombreamento
         %XdB=sqrt(sigma2)*randn;  
         XdB=0;
         
         PL_d_dB=PL_d0_dB+10.*n.*log10(d/d0)+XdB;      % Log-Distance+Sombreamento
         
         signal_path_matrix=compute_path_matrix(area_width,area_height,x_ap,y_ap,x(j),y(i));
         number_of_obstructions=compute_wall_obstructions(area_width,area_height,wall_v,wall_h,signal_path_matrix);
         
         % Perda Total das Obstruções (Paredes) - 6dB/parede de tijolos
        PL_Wall_dB=6.*number_of_obstructions;
        
        
        
        % --------------------------------------------------
        % Calculo da Potência Recebida
        % --------------------------------------------------
        
        if (d>d0)
            Pr_dBm(i,j)=Pt_dBm+Gt+Gr-PL_d_dB-PL_Wall_dB;
        else
            Pr_dBm(i,j)=Pt_dBm+Gt+Gr-PL_d0_dB-PL_Wall_dB;
        end
        
        %---------------------------------------------------
        % Rotina para cálculo da taxa de conexão
        %---------------------------------------------------
        if (Pr_dBm(i,j)>=-68) 
          Taxa(i,j)=54;
        elseif (Pr_dBm(i,j)>=-75)&(Pr_dBm(i,j)<-68) 
          Taxa(i,j)=36; 
        elseif (Pr_dBm(i,j)>=-79)&(Pr_dBm(i,j)<-75) 
          Taxa(i,j)=24;
        elseif (Pr_dBm(i,j)>=-82)&(Pr_dBm(i,j)<-79) 
          Taxa(i,j)=18; 
        elseif (Pr_dBm(i,j)>=-87)&(Pr_dBm(i,j)<-82)
          Taxa(i,j)=9; 
        elseif (Pr_dBm(i,j)>=-88)&(Pr_dBm(i,j)<-87) 
          Taxa(i,j)=6; 
        elseif (Pr_dBm(i,j)>=-89)&(Pr_dBm(i,j)<-88)
          Taxa(i,j)=1; 
          end
          
        
        
        % --------------------------------------------------
        % Rotina de ajuste devido passo do grid
        % --------------------------------------------------
        
        if (j>1)
            Pr_dBm(i,j-step_grid+1:j-1)=Pr_dBm(i,j);
            Taxa(i,j-step_grid+1:j-1)= Taxa(i,j); 
        end
         if (i>1)
            Pr_dBm(i-step_grid+1:i-1,j)=Pr_dBm(i,j);
            Taxa(i-step_grid+1:i-1,j)= Taxa(i,j); 
        end
        
        
    end
end

      % -----------------------------------------------------------------
      % Ajuste de Zeros na Matriz de Potência e Taxa
      % -----------------------------------------------------------------
      for i=1:length(y)
       for j=step_grid+1:step_grid:length(x)
            Pr_dBm(i,j-step_grid+1:j-1)= Pr_dBm(i,j);
       end
      end


xx=1:length(x);
yy=1:length(y);


% -------------------------------------------------
% Saída - Gráfico
% -------------------------------------------------

figure(7)

hold
surface(xx,yy,flipud(Pr_dBm),'FaceColor','interp')
shading interp
colormap(gca,'jet');


%colormap(flipud(colormap))
colorbar
%hold
draw_scenario(area_width,area_height,wall_v,wall_h)
%wall_matrix_final

