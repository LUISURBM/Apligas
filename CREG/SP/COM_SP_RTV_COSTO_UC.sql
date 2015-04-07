CREATE OR REPLACE PROCEDURE APLIGAS.COM_SP_RTV_COSTO_UC (
   PD_AD_USER_SESSION_ID          IN       NUMBER,
   PD_AD_CLIENT_ID                IN       NUMBER,
   PD_AD_ORG_ID                   IN       NUMBER,
   P_COM_UNIDAD_CONSTRUCTIVA_ID   IN       NUMBER,
   P_FECHA_CALCULO                IN       DATE,
   P_C_REGION_ID                  IN       NUMBER,
   P_C_CITY_ID                    IN       NUMBER,
   P_C_SECTOR_ID                  IN       NUMBER,
   P_TIPO_INVERSION               IN       CHAR,
   P_VALOR                        OUT      NUMBER,
   MSG_ERROR                      OUT      VARCHAR2,
   ERROR_SOURCE                   OUT      VARCHAR2
)
IS
   V_GRP_GEOGRAFICO_ID   NUMBER (10, 0);
   V_FECHA_APLICACION    DATE;
   V_TIPO_INDICE         CHAR (3);
   V_TIPO_INVERSION      CHAR (1);
   SPCALL_ERROR          EXCEPTION;
   VD_AD_CLIENT_ID       NUMBER (10, 0);
   VD_AD_ORG_ID          NUMBER (10, 0);
   VD_AD_USER_ID         NUMBER (10, 0);
BEGIN
   VD_AD_CLIENT_ID :=
      APLIGAS.ADM_FN_RTV_CLIENT_DEFAULT (PD_AD_USER_SESSION_ID,
                                         PD_AD_CLIENT_ID,
                                         PD_AD_ORG_ID
                                        );
   VD_AD_ORG_ID :=
      APLIGAS.ADM_FN_RTV_ORG_DEFAULT (PD_AD_USER_SESSION_ID,
                                      PD_AD_CLIENT_ID,
                                      PD_AD_ORG_ID
                                     );
   VD_AD_USER_ID :=
      APLIGAS.ADM_FN_RTV_USER_DEFAULT (PD_AD_USER_SESSION_ID,
                                       PD_AD_CLIENT_ID,
                                       PD_AD_ORG_ID
                                      );
   P_VALOR := NULL;
   V_GRP_GEOGRAFICO_ID :=
      APLIGAS.COM_FN_RTV_GRPGEOGRAFICO (VD_AD_USER_ID,
                                        VD_AD_CLIENT_ID,
                                        VD_AD_ORG_ID,
                                        P_C_REGION_ID,
                                        P_C_CITY_ID,
                                        P_C_SECTOR_ID
                                       );
   V_TIPO_INDICE :=
      APLIGAS.COM_FN_RTV_INDICE_COSTO (VD_AD_USER_ID,
                                       VD_AD_CLIENT_ID,
                                       VD_AD_ORG_ID
                                      );
   V_TIPO_INVERSION := P_TIPO_INVERSION;

   BEGIN
      SELECT C.TIPO_INVERSION_FIN
        INTO V_TIPO_INVERSION
        FROM APLIGAS.COM_POLITICA_COSTO C INNER JOIN APLIGAS.COM_POLITICA_CSTMUNIC M
             ON C.COM_POLITICA_COSTO_ID = M.COM_POLITICA_COSTO_ID
       WHERE C.FECHA_INICIAL <= P_FECHA_CALCULO
         AND P_FECHA_CALCULO <= C.FECHA_FINAL
         AND C.TIPO_INVERSION_INI = P_TIPO_INVERSION
         AND M.C_REGION_ID = P_C_REGION_ID
         AND M.C_CITY_ID = P_C_CITY_ID
         AND M.C_SECTOR_ID = P_C_SECTOR_ID
         AND C.ESTADO = 'A'
         AND M.ESTADO = 'A';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_TIPO_INVERSION := NULL;
   END;

   IF (V_TIPO_INVERSION IS NULL)
   THEN
      V_TIPO_INVERSION := '3';
   END IF;

   BEGIN
      SELECT MAX (FECHA_APLICACION)
        INTO V_FECHA_APLICACION
        FROM APLIGAS.COM_COSTO_UC
       WHERE COM_UNIDAD_CONSTRUCTIVA_ID = P_COM_UNIDAD_CONSTRUCTIVA_ID
         AND COM_GRUPO_GEOGRAFICO_ID = V_GRP_GEOGRAFICO_ID
         AND FECHA_APLICACION <= P_FECHA_CALCULO
         AND ESTADO = 'A'
         AND TIPO_INVERSION = V_TIPO_INVERSION;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_FECHA_APLICACION := NULL;
   END;

   IF (V_FECHA_APLICACION IS NULL AND V_GRP_GEOGRAFICO_ID <> 1)
   THEN
      BEGIN
         SELECT MAX (FECHA_APLICACION)
           INTO V_FECHA_APLICACION
           FROM APLIGAS.COM_COSTO_UC
          WHERE COM_UNIDAD_CONSTRUCTIVA_ID = P_COM_UNIDAD_CONSTRUCTIVA_ID
            AND COM_GRUPO_GEOGRAFICO_ID = 1
            AND FECHA_APLICACION <= P_FECHA_CALCULO
            AND ESTADO = 'A'
            AND TIPO_INVERSION = V_TIPO_INVERSION;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            V_FECHA_APLICACION := NULL;
      END;

      IF (V_FECHA_APLICACION IS NOT NULL)
      THEN
         V_GRP_GEOGRAFICO_ID := 1;
      END IF;
   END IF;

   IF (V_FECHA_APLICACION IS NULL)
   THEN
      BEGIN
         SELECT MAX (FECHA_APLICACION)
           INTO V_FECHA_APLICACION
           FROM APLIGAS.COM_COSTO_UC
          WHERE COM_UNIDAD_CONSTRUCTIVA_ID = P_COM_UNIDAD_CONSTRUCTIVA_ID
            AND COM_GRUPO_GEOGRAFICO_ID = V_GRP_GEOGRAFICO_ID
            AND FECHA_APLICACION <= P_FECHA_CALCULO
            AND ESTADO = 'A'
            AND TIPO_INVERSION IS NULL;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            V_FECHA_APLICACION := NULL;
      END;

      IF (V_FECHA_APLICACION IS NOT NULL)
      THEN
         V_TIPO_INVERSION := NULL;
      END IF;
   END IF;

   IF (V_FECHA_APLICACION IS NULL AND V_GRP_GEOGRAFICO_ID <> 1)
   THEN
      BEGIN
         SELECT MAX (FECHA_APLICACION)
           INTO V_FECHA_APLICACION
           FROM APLIGAS.COM_COSTO_UC
          WHERE COM_UNIDAD_CONSTRUCTIVA_ID = P_COM_UNIDAD_CONSTRUCTIVA_ID
            AND COM_GRUPO_GEOGRAFICO_ID = 1
            AND FECHA_APLICACION <= P_FECHA_CALCULO
            AND ESTADO = 'A'
            AND TIPO_INVERSION IS NULL;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            V_FECHA_APLICACION := NULL;
      END;

      IF (V_FECHA_APLICACION IS NOT NULL)
      THEN
         V_GRP_GEOGRAFICO_ID := 1;
         V_TIPO_INVERSION := NULL;
      END IF;
   END IF;

   IF (V_FECHA_APLICACION IS NOT NULL)
   THEN
      SELECT VALOR_UC
        INTO P_VALOR
        FROM APLIGAS.COM_COSTO_UC
       WHERE COM_UNIDAD_CONSTRUCTIVA_ID = P_COM_UNIDAD_CONSTRUCTIVA_ID
         AND COM_GRUPO_GEOGRAFICO_ID = V_GRP_GEOGRAFICO_ID
         AND FECHA_APLICACION = V_FECHA_APLICACION
         AND ESTADO = 'A'
         AND (   (    V_TIPO_INVERSION IS NOT NULL
                  AND TIPO_INVERSION = V_TIPO_INVERSION
                 )
              OR (V_TIPO_INVERSION IS NULL AND TIPO_INVERSION IS NULL)
             );

      P_VALOR :=
         APLIGAS.COM_FN_ACTUALIZAR_VALOR (VD_AD_USER_ID,
                                          VD_AD_CLIENT_ID,
                                          VD_AD_ORG_ID,
                                          V_TIPO_INDICE,
                                          V_FECHA_APLICACION,
                                          P_FECHA_CALCULO,
                                          P_VALOR
                                         );
   END IF;

   IF (V_FECHA_APLICACION IS NOT NULL)
   THEN
      SELECT VALOR_UC
        INTO P_VALOR
        FROM APLIGAS.COM_COSTO_UC
       WHERE COM_UNIDAD_CONSTRUCTIVA_ID = P_COM_UNIDAD_CONSTRUCTIVA_ID
         AND COM_GRUPO_GEOGRAFICO_ID = V_GRP_GEOGRAFICO_ID
         AND FECHA_APLICACION = V_FECHA_APLICACION
         AND ESTADO = 'A'
         AND (TIPO_INVERSION = '3');

      P_VALOR :=
         APLIGAS.COM_FN_ACTUALIZAR_VALOR (VD_AD_USER_ID,
                                          VD_AD_CLIENT_ID,
                                          VD_AD_ORG_ID,
                                          V_TIPO_INDICE,
                                          V_FECHA_APLICACION,
                                          P_FECHA_CALCULO,
                                          P_VALOR
                                         );
   END IF;

   IF (V_FECHA_APLICACION IS NOT NULL)
   THEN
      SELECT VALOR_UC
        INTO P_VALOR
        FROM APLIGAS.COM_COSTO_UC
       WHERE COM_UNIDAD_CONSTRUCTIVA_ID = P_COM_UNIDAD_CONSTRUCTIVA_ID
         AND COM_GRUPO_GEOGRAFICO_ID = 1
         AND FECHA_APLICACION = V_FECHA_APLICACION
         AND ESTADO = 'A'
         AND (TIPO_INVERSION = '3');

      P_VALOR :=
         APLIGAS.COM_FN_ACTUALIZAR_VALOR (VD_AD_USER_ID,
                                          VD_AD_CLIENT_ID,
                                          VD_AD_ORG_ID,
                                          V_TIPO_INDICE,
                                          V_FECHA_APLICACION,
                                          P_FECHA_CALCULO,
                                          P_VALOR
                                         );
   END IF;
EXCEPTION
   WHEN SPCALL_ERROR
   THEN
      ERROR_SOURCE := ERROR_SOURCE || ' - COM_SP_RTV_COSTO_UC';
      ROLLBACK;
   WHEN OTHERS
   THEN
      ERROR_SOURCE := SQLERRM || ' - COM_SP_RTV_COSTO_UC';
      MSG_ERROR := 'TRG-@4302@<br>';
      ROLLBACK;
END;
/