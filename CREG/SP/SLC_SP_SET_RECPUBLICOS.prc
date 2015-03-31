CREATE OR REPLACE PROCEDURE APLIGAS.SLC_SP_SET_RECPUBLICOS (
   PD_AD_USER_SESSION_ID   IN       NUMBER,
   PD_AD_CLIENT_ID         IN       NUMBER,
   PD_AD_ORG_ID            IN       NUMBER,
   P_SLC_TARIFARIA_ID      IN       NUMBER,
   MSG_ERROR               OUT      VARCHAR2,
   ERROR_SOURCE            OUT      VARCHAR2
)
IS
   V_TIPO_MUNICIPIO            CHAR (1);
   V_TIENE_APORTES             CHAR (1);
   V_GST_TARIFARIA_ID          NUMBER (10, 0);
   V_GST_TARIFARIA_REF_ID      NUMBER (10, 0);
   V_C_SECTOR_ID               NUMBER (10, 0);
   V_C_REGION_ID               NUMBER (10, 0);
   V_C_CITY_ID                 NUMBER (10, 0);
   V_SLC_MERCADO_ESPECIAL_ID   NUMBER (10, 0);
   V_MERCADO                   NUMBER (10, 0);
   V_MERCADO_ESPECIAL          NUMBER (10, 0);
   V_IND_APORTE_ANT            NUMBER;
   V_IND_APORTE NUMBER;
   SPCALL_ERROR                EXCEPTION;
   SPLOGIC_ERROR               EXCEPTION;
   VD_AD_CLIENT_ID             NUMBER (10, 0);
   VD_AD_ORG_ID                NUMBER (10, 0);
   VD_AD_USER_ID               NUMBER (10, 0);
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
   V_TIENE_APORTES := NULL;

   BEGIN
      SELECT TIPO_MUNICIPIO
        INTO V_TIPO_MUNICIPIO
        FROM APLIGAS.SLC_TARIFARIA
       WHERE SLC_TARIFARIA_ID = P_SLC_TARIFARIA_ID;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_TIPO_MUNICIPIO := NULL;
   END;

   IF (V_TIPO_MUNICIPIO = 'R')
   THEN
      V_C_SECTOR_ID := NULL;
      V_SLC_MERCADO_ESPECIAL_ID := NULL;

      DECLARE
         CURSOR C_MERCADO
         IS
            SELECT SLC_MERCADO_ID, GST_TARIFARIA_REF_ID, C_REGION_ID,
                   C_CITY_ID
              FROM APLIGAS.SLC_MERCADO
             WHERE SLC_TARIFARIA_ID = P_SLC_TARIFARIA_ID AND ESTADO = 'A';
      BEGIN
         OPEN C_MERCADO;

         FETCH C_MERCADO
          INTO V_MERCADO, V_GST_TARIFARIA_REF_ID, V_C_REGION_ID, V_C_CITY_ID;

         WHILE C_MERCADO%FOUND
         LOOP
            IF (V_GST_TARIFARIA_REF_ID IS NOT NULL)
            THEN
               APLIGAS.GST_SP_RTV_RECPUBLICOS_X_MUN (VD_AD_CLIENT_ID,
                                                     VD_AD_ORG_ID,
                                                     VD_AD_USER_ID,
                                                     V_GST_TARIFARIA_REF_ID,
                                                     V_C_REGION_ID,
                                                     V_C_CITY_ID,
                                                     V_C_SECTOR_ID,
                                                     NULL,
                                                     V_IND_APORTE_ANT,
                                                     MSG_ERROR,
                                                     ERROR_SOURCE
                                                    );
            END IF;

            IF (V_GST_TARIFARIA_REF_ID IS NULL)
            THEN
               V_IND_APORTE_ANT := 'N';
            END IF;

            APLIGAS.SLC_SP_RTV_RECPUBLICOS_X_MUN (VD_AD_CLIENT_ID,
                                                  VD_AD_ORG_ID,
                                                  VD_AD_USER_ID,
                                                  P_SLC_TARIFARIA_ID,
                                                  V_C_REGION_ID,
                                                  V_C_CITY_ID,
                                                  V_C_SECTOR_ID,
                                                  V_SLC_MERCADO_ESPECIAL_ID,
                                                  V_IND_APORTE,
                                                  MSG_ERROR,
                                                  ERROR_SOURCE
                                                 );
            V_TIENE_APORTES :=
               APLIGAS.COM_FN_RTV_APORTE (VD_AD_CLIENT_ID,
                                          VD_AD_ORG_ID,
                                          VD_AD_USER_ID,
                                          V_IND_APORTE,
                                          V_IND_APORTE_ANT,
                                          V_TIENE_APORTES
                                         );

            UPDATE APLIGAS.SLC_MERCADO
               SET UPDATED = CURRENT_TIMESTAMP,
                   UPDATEDBY = VD_AD_USER_ID,
                   TIENE_APORTES = V_TIENE_APORTES
             WHERE SLC_MERCADO_ID = V_SLC_MERCADO_ID;

            FETCH C_MERCADO
             INTO V_MERCADO, V_GST_TARIFARIA_REF_ID, V_C_REGION_ID,
                  V_C_CITY_ID;
         END LOOP;

         CLOSE C_MERCADO;
      END;
   END IF;

   IF (V_TIPO_MUNCIPIO = 'E')
   THEN
      DECLARE
         CURSOR C_MERCADO_ESPECIAL
         IS
            SELECT SLC_MERCADO_ESPECIAL_ID, GST_TARIFARIA_REF_ID,
                   C_REGION_ID, C_CITY_ID, C_SECTOR_ID
              FROM APLIGAS.SLC_MERCADO_ESPECIAL
             WHERE SLC_TARIFARIA_ID = P_SLC_TARIFARIA_ID AND ESTADO = 'A';
      BEGIN
         OPEN C_MERCADO_ESPECIAL;

         FETCH C_MERCADO_ESPECIAL
          INTO V_SLC_MERCADO_ESPECIAL_ID, V_C_REGION_ID, V_C_CITY_ID,
               V_C_SECTOR_ID;

         WHILE C_MERCADO_ESPECIAL%FOUND
         LOOP
            IF (V_GST_TARIFARIA_REF_ID IS NOT NULL)
            THEN
               APLIGAS.GST_SP_RTV_RECPUBLICOS_X_MUN (VD_AD_CLIENT_ID,
                                                     VD_AD_ORG_ID,
                                                     VD_AD_USER_ID,
                                                     V_GST_TARIFARIA_REF_ID,
                                                     V_C_REGION_ID,
                                                     V_C_CITY_ID,
                                                     V_C_SECTOR_ID,
                                                     NULL,
                                                     V_IND_APORTE_ANT,
                                                     MSG_ERROR,
                                                     ERROR_SOURCE
                                                    );
            END IF;

            IF (V_GST_TARIFARIA_REF_ID IS NULL)
            THEN
               V_IND_APORTE_ANT := 'N';
            END IF;

            APLIGAS.SLC_SP_RTV_RECPUBLICOS_X_MUN (VD_AD_CLIENT_ID,
                                                  VD_AD_ORG_ID,
                                                  VD_AD_USER_ID,
                                                  P_SLC_TARIFARIA_ID,
                                                  V_C_REGION_ID,
                                                  V_C_CITY_ID,
                                                  V_C_SECTOR_ID,
                                                  V_SLC_MERCADO_ESPECIAL_ID,
                                                  V_IND_APORTE,
                                                  MSG_ERROR,
                                                  ERROR_SOURCE
                                                 );
            V_TIENE_APORTES :=
               APLIGAS.COM_FN_RTV_APORTE (VD_AD_CLIENT_ID,
                                          VD_AD_ORG_ID,
                                          VD_AD_USER_ID,
                                          V_IND_APORTE,
                                          V_IND_APORTE_ANT,
                                          V_TIENE_APORTES,
                                          MSG_ERROR
                                         );

            UPDATE APLIGAS.SLC_MERCADO_ESPECIAL
               SET UPDATED = CURRENT_TIMESTAMP,
                   UPDATEDBY = VD_AD_USER_ID,
                   TIENE_APORTES = V_TIENE_APORTES
             WHERE SLC_MERCADO_ESPECIAL_ID = V_SLC_MERCADO_ESPECIAL_ID;

            FETCH C_MERCADO_ESPECIAL
             INTO V_SLC_MERCADO_ESPECIAL_ID, V_C_REGION_ID, V_C_CITY_ID,
                  V_C_SECTOR_ID;
         END LOOP;

         CLOSE C_MERCADO_ESPECIAL;
      END;
   END IF;
EXCEPTION
   WHEN SPLOGIC_ERROR
   THEN
      ERROR_SOURCE := ERROR_SOURCE || ' - SLC_SP_SET_RECPUBLICOS';
      ROLLBACK;
   WHEN SPCALL_ERROR
   THEN
      ERROR_SOURCE := ERROR_SOURCE || ' - SLC_SP_SET_RECPUBLICOS';
      ROLLBACK;
   WHEN OTHERS
   THEN
      ERROR_SOURCE := SQLERRM || ' - SLC_SP_SET_RECPUBLICOS';
      MSG_ERROR := 'TRG-@4302@<BR>';
      ROLLBACK;
END;